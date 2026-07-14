-- Esquema del backend de Fog of War (Supabase / Postgres).
--
-- Cómo aplicarlo: panel de Supabase → SQL Editor → pegar este archivo entero →
-- Run. Es idempotente (IF NOT EXISTS / OR REPLACE): se puede re-ejecutar.
--
-- Principios (ver lib/cloud/cloud_sync.dart):
--  * El progreso se guarda por IDs estables; los PUNTOS NO se almacenan, se
--    derivan (vista user_scores) → nunca se acepta un total del cliente.
--  * Row Level Security en todo: cada usuario solo lee/escribe lo suyo.
--  * La niebla viaja por tiles Z16: una fila por tile con un bitmap de 256
--    celdas (32 bytes) en base64 — el mismo formato de lib/fog/fog_codec.dart.
--
--  * Leaderboard REAL: el ranking se sirve con dos RPCs (global_leaderboard y
--    collection_leaderboard) que leen player_stats/profiles, tablas mantenidas
--    por triggers y NUNCA expuestas al Data API. El contenido (puntos por POI,
--    colecciones) sigue viviendo en el cliente (Google Sheet): las RPCs
--    reciben el mapa de puntos / la lista de POIs como parámetro.
--  * Anti-trampas: un trigger sobre fog_tiles lleva un presupuesto de celdas
--    por usuario que se acumula con el tiempo (celdas/hora) y rechaza ráfagas
--    imposibles. Ver fog_stats_guard() para los límites y su justificación.

-- ---------------------------------------------------------------------------
-- Niebla: un bitmap por tile Z16 tocado. PK compuesta = upsert natural.
create table if not exists public.fog_tiles (
  user_id    uuid not null references auth.users (id) on delete cascade,
  x          integer not null,
  y          integer not null,
  -- 32 bytes en base64 (44 chars). Texto y no bytea para que el JSON del
  -- cliente viaje sin sorpresas; el servidor lo decodifica al puntuar.
  bitmap     text not null check (octet_length(decode(bitmap, 'base64')) = 32),
  updated_at timestamptz not null default now(),
  primary key (user_id, x, y)
);

-- POIs descubiertos, atalayas activadas y logros: conjuntos de IDs estables.
create table if not exists public.discovered_pois (
  user_id       uuid not null references auth.users (id) on delete cascade,
  poi_id        text not null,
  discovered_at timestamptz not null default now(),
  primary key (user_id, poi_id)
);

create table if not exists public.watchtowers_activated (
  user_id       uuid not null references auth.users (id) on delete cascade,
  watchtower_id text not null,
  activated_at  timestamptz not null default now(),
  primary key (user_id, watchtower_id)
);

create table if not exists public.achievements_unlocked (
  user_id        uuid not null references auth.users (id) on delete cascade,
  achievement_id text not null,
  unlocked_at    timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

-- Ajustes de la cuenta (avatar, idioma forzado, misión fijada).
create table if not exists public.user_settings (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  avatar_icon  integer not null default 0,
  avatar_color integer not null default 0,
  locale       text,          -- null = idioma del sistema
  mission_id   text,          -- null = sin misión fijada
  updated_at   timestamptz not null default now()
);

-- updated_at automático al modificar una fila.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists fog_tiles_touch on public.fog_tiles;
create trigger fog_tiles_touch before update on public.fog_tiles
  for each row execute function public.touch_updated_at();

drop trigger if exists user_settings_touch on public.user_settings;
create trigger user_settings_touch before update on public.user_settings
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security: cada usuario, solo sus filas. (La anon key sin sesión
-- no pasa ninguna política: sin login no se lee ni escribe nada.)
alter table public.fog_tiles             enable row level security;
alter table public.discovered_pois       enable row level security;
alter table public.watchtowers_activated enable row level security;
alter table public.achievements_unlocked enable row level security;
alter table public.user_settings         enable row level security;

do $$
declare t text;
begin
  foreach t in array array['fog_tiles', 'discovered_pois',
                           'watchtowers_activated', 'achievements_unlocked',
                           'user_settings'] loop
    execute format(
      'drop policy if exists "own rows" on public.%I;
       create policy "own rows" on public.%I
         for all to authenticated
         using (auth.uid() = user_id)
         with check (auth.uid() = user_id);', t, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Privilegios del Data API. Con "Automatically expose new tables" DESACTIVADO
-- al crear el proyecto (lo recomendado), las tablas nuevas no se exponen a la
-- API: hay que conceder los permisos a mano, aquí. Solo al rol authenticated
-- (con sesión iniciada); el rol anon no recibe nada. RLS sigue mandando por
-- encima de estos GRANTs: aun con permiso de tabla, cada uno solo ve lo suyo.
grant usage on schema public to authenticated;
grant select, insert, update, delete
  on public.fog_tiles, public.discovered_pois, public.watchtowers_activated,
     public.achievements_unlocked, public.user_settings
  to authenticated;

-- ---------------------------------------------------------------------------
-- LEADERBOARD REAL + ANTI-TRAMPAS
-- ---------------------------------------------------------------------------

-- La vista user_scores (el germen del leaderboard) queda sustituida por
-- player_stats + las RPCs de abajo: mismo principio (puntuar en servidor,
-- nunca aceptar totales del cliente) pero O(1) por consulta en vez de
-- recontar todos los bitmaps en cada lectura.
drop view if exists public.user_scores;

-- Nombre público de cada jugador (lo único de la cuenta que ven los demás).
-- Se crea solo, con un trigger sobre auth.users; el nombre sale de los
-- metadatos de Google. Nunca se expone email ni user_id ajenos.
create table if not exists public.profiles (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
);

-- Contadores por usuario mantenidos por TRIGGERS (nunca los escribe el
-- cliente): celdas totales (bits a 1 de sus bitmaps) y nº de POIs. Además
-- lleva el presupuesto anti-trampas:
--   budget_cells = celdas que aún puede subir; se acumula con el tiempo a
--   razón de kBudgetPerHour hasta el tope (= el valor default de la columna).
-- Una celda mide ~29-38 m de lado (Z20), así que 500.000 celdas ≈ 500 km²:
-- presupuesto inicial de sobra para el progreso local previo a crear la
-- cuenta, e inalcanzable andando; ver fog_stats_guard().
create table if not exists public.player_stats (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  cells        bigint  not null default 0,
  pois         integer not null default 0,
  budget_cells numeric not null default 500000,
  budget_at    timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

drop trigger if exists player_stats_touch on public.player_stats;
create trigger player_stats_touch before update on public.player_stats
  for each row execute function public.touch_updated_at();

-- Ambas tablas: RLS activado SIN políticas y sin GRANTs → invisibles para el
-- Data API. Solo se leen a través de las RPCs security definer del final.
alter table public.profiles     enable row level security;
alter table public.player_stats enable row level security;

-- Perfil automático al crear la cuenta: nombre de Google, o la parte local
-- del email, o un genérico. security definer: lo dispara auth, no el cliente.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Explorador'))
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Mantiene cells al escribir fog_tiles y aplica el ANTI-TRAMPAS: el
-- presupuesto se recarga a kBudgetPerHour (15.000 celdas/h: un coche rápido
-- con radio de desvelado de 50 m genera ~12.000/h; andando son ~600/h) hasta
-- el tope de 500.000 (≈ 33 h de coche ininterrumpido: cubre semanas de juego
-- legítimo sin sincronizar). Si una subida excede el presupuesto, la
-- transacción entera se rechaza; el cliente la reintentará sola (y seguirá
-- fallando: un tramposo queda congelado, no borrado).
-- AFTER por fila: con ON CONFLICT solo cuenta lo que de verdad se escribe.
create or replace function public.fog_stats_guard()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  kBudgetPerHour constant numeric := 15000;
  kBudgetCap     constant numeric := 500000; -- = default de budget_cells
  delta     bigint;
  remaining numeric;
begin
  if tg_op = 'DELETE' then
    -- Solo pasa al borrar la cuenta (cascade); sin recarga de presupuesto.
    update public.player_stats s
       set cells = greatest(s.cells - bit_count(decode(old.bitmap, 'base64')), 0)
     where s.user_id = old.user_id;
    return null;
  end if;

  delta := bit_count(decode(new.bitmap, 'base64'));
  if tg_op = 'UPDATE' then
    delta := delta - bit_count(decode(old.bitmap, 'base64'));
  end if;

  insert into public.player_stats (user_id) values (new.user_id)
    on conflict (user_id) do nothing;

  update public.player_stats s
     set budget_cells = least(kBudgetCap,
           s.budget_cells
             + kBudgetPerHour * extract(epoch from now() - s.budget_at) / 3600)
           - greatest(delta, 0),
         budget_at = now(),
         cells = greatest(s.cells + delta, 0)
   where s.user_id = new.user_id
   returning s.budget_cells into remaining;

  if remaining < 0 then
    raise exception 'fog upload rejected: cell budget exceeded'
      using errcode = 'P0001';
  end if;
  return null;
end $$;

drop trigger if exists fog_tiles_stats on public.fog_tiles;
create trigger fog_tiles_stats after insert or update or delete on public.fog_tiles
  for each row execute function public.fog_stats_guard();

-- Mantiene el contador de POIs (el upsert del cliente usa ignoreDuplicates,
-- así que un AFTER INSERT solo se dispara con filas realmente nuevas).
create or replace function public.poi_stats_count()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    insert into public.player_stats (user_id) values (new.user_id)
      on conflict (user_id) do nothing;
    update public.player_stats s set pois = s.pois + 1
     where s.user_id = new.user_id;
  else
    update public.player_stats s set pois = greatest(s.pois - 1, 0)
     where s.user_id = old.user_id;
  end if;
  return null;
end $$;

drop trigger if exists discovered_pois_stats on public.discovered_pois;
create trigger discovered_pois_stats
  after insert or delete on public.discovered_pois
  for each row execute function public.poi_stats_count();

-- Backfill idempotente para cuentas creadas ANTES de estos triggers: perfil
-- y contadores calculados de sus datos ya subidos. Si la fila existe, no toca.
insert into public.profiles (user_id, display_name)
select u.id, coalesce(
    nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'name'), ''),
    nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
    'Explorador')
from auth.users u
on conflict (user_id) do nothing;

insert into public.player_stats (user_id, cells, pois)
select u.id,
  coalesce((select sum(bit_count(decode(f.bitmap, 'base64')))
              from public.fog_tiles f where f.user_id = u.id), 0),
  coalesce((select count(*)
              from public.discovered_pois d where d.user_id = u.id), 0)
from auth.users u
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- RPCs del leaderboard. El contenido vive en el cliente (Google Sheet), así
-- que el cliente manda su catálogo como parámetro: poi_points = {"poi_id":
-- puntos}. Un cliente manipulado solo distorsiona SU vista del ranking, nunca
-- lo almacenado. Devuelven el top N + siempre tu propia fila (is_you) aunque
-- quedes fuera del top. security definer: leen tablas sin exponer.

-- Ranking GLOBAL: celdas * cell_points + puntos de los POIs descubiertos.
create or replace function public.global_leaderboard(
  cell_points integer default 1,
  poi_points  jsonb   default '{}'::jsonb,
  top_count   integer default 10
) returns table (rank bigint, display_name text, score bigint, is_you boolean)
language sql stable security definer set search_path = '' as $$
  with scores as (
    select s.user_id,
           coalesce(p.display_name, 'Explorador') as name,
           (s.cells * cell_points + coalesce((
             select sum((poi_points ->> d.poi_id)::bigint)
               from public.discovered_pois d
              where d.user_id = s.user_id and poi_points ? d.poi_id), 0))::bigint
             as pts
      from public.player_stats s
      left join public.profiles p on p.user_id = s.user_id
  ), ranked as (
    select row_number() over (order by pts desc, name, user_id) as pos, *
      from scores
  )
  select pos, name, pts, user_id = auth.uid()
    from ranked
   where pos <= top_count or user_id = auth.uid()
   order by pos
$$;

-- Ranking de UNA colección: nº de POIs descubiertos de la lista recibida.
create or replace function public.collection_leaderboard(
  poi_ids   text[],
  top_count integer default 10
) returns table (rank bigint, display_name text, score bigint, is_you boolean)
language sql stable security definer set search_path = '' as $$
  with counts as (
    select s.user_id,
           coalesce(p.display_name, 'Explorador') as name,
           coalesce((
             select count(*) from public.discovered_pois d
              where d.user_id = s.user_id and d.poi_id = any (poi_ids)), 0) as pts
      from public.player_stats s
      left join public.profiles p on p.user_id = s.user_id
  ), ranked as (
    select row_number() over (order by pts desc, name, user_id) as pos, *
      from counts
  )
  select pos, name, pts, user_id = auth.uid()
    from ranked
   where pos <= top_count or user_id = auth.uid()
   order by pos
$$;

-- Solo con sesión iniciada (las funciones nacen ejecutables por PUBLIC).
revoke all on function public.global_leaderboard(integer, jsonb, integer)
  from public, anon;
revoke all on function public.collection_leaderboard(text[], integer)
  from public, anon;
grant execute on function public.global_leaderboard(integer, jsonb, integer)
  to authenticated;
grant execute on function public.collection_leaderboard(text[], integer)
  to authenticated;
