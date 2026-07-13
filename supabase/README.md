# Backend (Supabase): puesta en marcha

El código del cliente ya está (`lib/cloud/`), pero queda inerte hasta rellenar
`lib/cloud/cloud_config.dart`. Pasos, una sola vez (~15 min):

## 1. Crear el proyecto

1. https://supabase.com → **Start your project** → entrar (con GitHub o Google).
2. **New project**: nombre `fog-of-war`, región `eu-west` (o la más cercana),
   contraseña de base de datos cualquiera fuerte (apúntala, casi nunca hace falta).
3. Al terminar, en **Project Settings → API Keys**: copiar la **Project URL** y
   la **publishable key** (`sb_publishable_…`).

## 2. Crear las tablas

1. En el panel: **SQL Editor** → pegar el contenido entero de `schema.sql` → **Run**.
   (Es idempotente: se puede volver a ejecutar sin romper nada.)

## 3. Login con Google

1. https://console.cloud.google.com → crear proyecto (o usar uno existente) →
   **APIs & Services → OAuth consent screen**: tipo External, rellenar nombre y
   correo (con eso basta para probar).
2. **Credentials → Create credentials → OAuth client ID** → tipo **Web
   application** → en *Authorized redirect URIs* añadir:
   `https://<ref-del-proyecto>.supabase.co/auth/v1/callback`
   (la URL exacta la muestra Supabase en el paso siguiente).
3. En Supabase: **Authentication → Sign In / Providers → Google** → activar y
   pegar el **Client ID** y el **Client Secret** del paso anterior.
4. En Supabase: **Authentication → URL Configuration → Redirect URLs** →
   añadir `fogofwar://login-callback`.

No hace falta cliente OAuth de Android ni registrar SHA-1: el login va por
navegador y vuelve a la app por ese deep link (ver `lib/cloud/cloud_auth.dart`).

## 4. Conectar la app

En `lib/cloud/cloud_config.dart`, rellenar `kSupabaseUrl` y
`kSupabasePublishableKey` con lo copiado en el paso 1. Compilar e instalar:
en Ajustes aparece la sección **Cuenta**.

## Qué se sincroniza

Niebla (bitmaps por tile Z16), POIs descubiertos, atalayas, logros y ajustes
(avatar/idioma/misión). Local-first: sin sesión o sin red la app funciona
exactamente igual; al iniciar sesión se UNE lo local con lo de la cuenta (el
progreso nunca se pierde). Los puntos no se suben: los calcula el servidor
(vista `user_scores`), base del futuro leaderboard real.
