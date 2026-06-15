// Traducción de textos que viven en los datos (no en la UI): nombres de los
// estilos de mapa y nombre/descripción de las colecciones temáticas.
//
// Los datos (kMapStyles, kPoiCollections) siguen siendo la fuente de IDs y
// aspecto; aquí solo resolvemos su TEXTO visible al idioma actual. Si aparece
// un id/índice nuevo sin traducir, se cae al texto original del dato.

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

/// Nombre traducido de una colección por su id. [fallback] = nombre del dato.
String localizedCollectionName(AppLocalizations l, String id, String fallback) {
  switch (id) {
    case 'gaudi':
      return l.collGaudiName;
    case 'imprescindibles':
      return l.collEssentialName;
    case 'otaku':
      return l.collOtakuName;
    case 'museos':
      return l.collMuseumsName;
    case 'tapas':
      return l.collTapasName;
    case 'michelins':
      return l.collMichelinName;
    default:
      return fallback;
  }
}

/// Descripción traducida de una colección por su id. [fallback] = dato.
String localizedCollectionDescription(
    AppLocalizations l, String id, String fallback) {
  switch (id) {
    case 'gaudi':
      return l.collGaudiDesc;
    case 'imprescindibles':
      return l.collEssentialDesc;
    case 'otaku':
      return l.collOtakuDesc;
    case 'museos':
      return l.collMuseumsDesc;
    case 'tapas':
      return l.collTapasDesc;
    case 'michelins':
      return l.collMichelinDesc;
    default:
      return fallback;
  }
}
