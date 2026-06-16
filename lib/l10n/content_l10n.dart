// Traducción de textos que viven en los datos (no en la UI): nombres de los
// estilos de mapa.
//
// Los estilos (kMapStyles) siguen siendo la fuente de IDs y aspecto; aquí solo
// resolvemos su TEXTO visible al idioma actual. Si aparece un id sin traducir,
// se cae al texto original del dato.
//
// NOTA: las colecciones YA NO se traducen aquí. Ahora cada PoiCollection lleva
// su texto por idioma en los propios datos (ver PoiCollection.localizedName/
// localizedDescription), porque el contenido puede venir de la hoja externa.

import 'app_localizations.dart';

/// Nombre traducido de un estilo de mapa por su clave estable (MapStyle.nameKey).
/// [fallback] es el nombre original del dato (para estilos sin traducción).
String localizedMapStyleName(AppLocalizations l, String key, String fallback) {
  switch (key) {
    case 'voyager':
      return l.mapStyleVoyager;
    case 'light':
      return l.mapStyleLight;
    case 'dark':
      return l.mapStyleDark;
    case 'osm':
      return l.mapStyleOsm;
    case 'satellite':
      return l.mapStyleSatellite;
    case 'topographic':
      return l.mapStyleTopographic;
    case 'explorer':
      return l.mapStyleExplorer;
    case 'sepia':
      return l.mapStyleSepia;
    case 'bright':
      return l.mapStyleBright;
    case 'liberty':
      return l.mapStyleLiberty;
    case 'game':
      return l.mapStyleGame;
    default:
      return fallback;
  }
}
