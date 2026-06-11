// Traducción de textos que viven en los datos (no en la UI): nombres de los
// estilos de mapa y nombre/descripción de las colecciones temáticas.
//
// Los datos (kMapStyles, kPoiCollections) siguen siendo la fuente de IDs y
// aspecto; aquí solo resolvemos su TEXTO visible al idioma actual. Si aparece
// un id/índice nuevo sin traducir, se cae al texto original del dato.

import 'app_localizations.dart';

/// Nombre traducido de un estilo de mapa por su índice en kMapStyles.
/// [fallback] es el nombre original del dato (para estilos sin traducción).
String localizedMapStyleName(AppLocalizations l, int index, String fallback) {
  switch (index) {
    case 0:
      return l.mapStyleVoyager;
    case 1:
      return l.mapStyleLight;
    case 2:
      return l.mapStyleDark;
    case 3:
      return l.mapStyleOsm;
    case 4:
      return l.mapStyleSatellite;
    case 5:
      return l.mapStyleTopographic;
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
