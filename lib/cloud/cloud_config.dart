// Configuración del backend (Supabase).
//
// Igual que content_config.dart con la Google Sheet: las credenciales viven
// aquí, en una constante, y con los valores VACÍOS toda la parte de nube queda
// desactivada (la app funciona 100% local, como siempre). Rellenar al crear el
// proyecto en https://supabase.com (Project Settings → API Keys).
//
// La clave "publishable" NO es un secreto (va en el cliente por diseño): la
// seguridad la pone Row Level Security en el servidor (ver
// supabase/schema.sql).

/// URL del proyecto de Supabase (la base, sin /rest/v1: la librería añade
/// cada ruta). Vacío = nube desactivada.
const String kSupabaseUrl = 'https://oizgsxwkbsvmgroypfyr.supabase.co';

/// Clave pública del proyecto: la "publishable key" (sb_publishable_…); la
/// "anon key" legacy también funciona. Vacío = nube desactivada.
const String kSupabasePublishableKey =
    'sb_publishable_LQ4f45bKFK2vr3FwfIMYTw_AJ7tlxwf';

/// ¿Hay backend configurado? Si es false, no se inicializa Supabase y los
/// botones de cuenta no se muestran.
bool get kCloudConfigured =>
    kSupabaseUrl.isNotEmpty && kSupabasePublishableKey.isNotEmpty;

/// Adónde vuelve el navegador tras el login con Google. Tiene que coincidir
/// con el intent-filter del AndroidManifest y estar en la lista de Redirect
/// URLs del panel de Supabase (Authentication → URL Configuration).
const String kAuthRedirectUri = 'fogofwar://login-callback';
