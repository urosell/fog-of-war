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
-- Anti-trampas pendiente (cuando haya leaderboard real): validar en servidor
-- la velocidad de descubrimiento (celdas/hora por usuario, p. ej. con un
-- trigger o Edge Function que rechace ráfagas imposibles). El primer paso ya
-- está dado: la puntuación se calcula aquí y no en el cliente.

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
-- Puntuación calculada EN SERVIDOR (germen del leaderboard real): celdas
-- descubiertas (bits a 1 de todos los bitmaps) y POIs. Los puntos por POI
-- según categoría se sumarán cuando el contenido viva en una tabla; de
-- momento el ranking del cliente sigue siendo local/simulado.
create or replace view public.user_scores
with (security_invoker = true) as
select
  u.id as user_id,
  coalesce((select sum(bit_count(decode(f.bitmap, 'base64')))
              from public.fog_tiles f where f.user_id = u.id), 0) as cells,
  coalesce((select count(*)
              from public.discovered_pois p where p.user_id = u.id), 0) as pois
from auth.users u;
