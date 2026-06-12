// Estilos de mapa base disponibles en el juego.
//
// Cada estilo es simplemente un servidor de "tiles" (las imágenes del mapa) con
// un aspecto distinto. Cambiar de estilo = cambiar la URL del TileLayer.
//
// Todos estos estilos son de uso libre y NO necesitan clave de API, así que
// valen para probar y para el MVP. Antes de publicar hay que mostrar la
// atribución (campo [attribution]) visible en pantalla, que es obligatoria.

import 'dart:ui' show Color;

/// Un estilo de mapa: nombre legible + de dónde se descargan sus tiles.
class MapStyle {
  /// Nombre que se muestra al usuario (ej. "Satélite").
  final String name;

  /// Plantilla de URL de los tiles, con {z}/{x}/{y} (y opcional {s}).
  final String urlTemplate;

  /// Subdominios para repartir la carga (solo se usan si la URL tiene {s}).
  final List<String> subdomains;

  /// Texto de atribución obligatorio para este proveedor.
  final String attribution;

  /// Matriz de color 4x5 opcional (20 valores) que se aplica a cada tile para
  /// darle un "humor" distinto (desaturar, oscurecer, teñir). Null = sin filtro,
  /// el mapa se ve tal cual lo sirve el proveedor.
  final List<double>? colorMatrix;

  /// Color del velo de niebla a juego con este estilo. Null = usa el color por
  /// defecto del juego (gris azulado). Conviene mantener la misma opacidad para
  /// que la sensación de "cuánto tapa la niebla" no cambie entre estilos.
  final Color? fogColor;

  const MapStyle({
    required this.name,
    required this.urlTemplate,
    this.subdomains = const [],
    required this.attribution,
    this.colorMatrix,
    this.fogColor,
  });
}

/// Construye una matriz de color 4x5 (para [ColorFilter.matrix]) que primero
/// ajusta la [saturation] (1 = igual, 0 = gris) y el [brightness] (1 = igual),
/// y luego suma un tinte fijo (offsets [tintR]/[tintG]/[tintB] en escala 0..255).
/// Pensada para dar a los tiles un aspecto más "de videojuego" sin tocarlos.
List<double> mapColorMatrix({
  double saturation = 1.0,
  double brightness = 1.0,
  double tintR = 0,
  double tintG = 0,
  double tintB = 0,
}) {
  // Luminancia Rec. 709 (cuánto aporta cada canal al brillo percibido).
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final s = saturation, b = brightness;
  final sr = (1 - s) * lr, sg = (1 - s) * lg, sb = (1 - s) * lb;
  return <double>[
    b * (sr + s), b * sg, b * sb, 0, tintR,
    b * sr, b * (sg + s), b * sb, 0, tintG,
    b * sr, b * sg, b * (sb + s), 0, tintB,
    0, 0, 0, 1, 0,
  ];
}

/// URL de los tiles base OSCUROS de CARTO, reutilizada por los estilos con
/// tinte: parten de un mapa oscuro (legible, sin "lavar" de blanco) y solo
/// cambian el filtro de color para darles un humor distinto.
const String _darkUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
const List<String> _cartoSubdomains = ['a', 'b', 'c', 'd'];
const String _cartoAttribution = '© OpenStreetMap, © CARTO';

/// Estilo por defecto al arrancar (índice en kMapStyles): el "Explorador", un
/// mapa oscuro con un tinte frío para que no se vea plano ni demasiado claro.
const int kDefaultStyleIndex = 6;

/// Lista de estilos entre los que el jugador puede ir rotando. Los seis primeros
/// son proveedores tal cual; los dos últimos reaprovechan los tiles Voyager con
/// un filtro de color para darles carácter (ver [kDefaultStyleIndex]).
final List<MapStyle> kMapStyles = [
  MapStyle(
    name: 'Voyager',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    attribution: '© OpenStreetMap, © CARTO',
  ),
  MapStyle(
    name: 'Claro',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    attribution: '© OpenStreetMap, © CARTO',
  ),
  MapStyle(
    name: 'Oscuro',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    attribution: '© OpenStreetMap, © CARTO',
  ),
  MapStyle(
    name: 'OSM clásico',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap',
  ),
  MapStyle(
    name: 'Satélite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri, Maxar, Earthstar Geographics',
  ),
  MapStyle(
    name: 'Topográfico',
    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    attribution: '© OpenStreetMap, © OpenTopoMap (CC-BY-SA)',
  ),
  // --- Estilos con carácter (tiles OSCUROS + filtro de color) ---
  // Índice 6: "Explorador" — mapa oscuro con un tinte frío azul-verdoso que
  // pega con la niebla y el acento turquesa. Por defecto (kDefaultStyleIndex).
  MapStyle(
    name: 'Explorador',
    urlTemplate: _darkUrl,
    subdomains: _cartoSubdomains,
    attribution: _cartoAttribution,
    colorMatrix: mapColorMatrix(
      saturation: 1.1,
      brightness: 1.0,
      tintR: -4,
      tintG: 4,
      tintB: 12,
    ),
    // Niebla azul fría a juego con el mapa noche.
    fogColor: Color(0xE6384258),
  ),
  // Índice 7: "Ámbar" — mapa oscuro con tinte cálido, aire nocturno de farolas.
  MapStyle(
    name: 'Ámbar',
    urlTemplate: _darkUrl,
    subdomains: _cartoSubdomains,
    attribution: _cartoAttribution,
    colorMatrix: mapColorMatrix(
      saturation: 1.1,
      brightness: 1.0,
      tintR: 16,
      tintG: 6,
      tintB: -10,
    ),
    // Niebla marrón cálida a juego con el mapa ámbar.
    fogColor: Color(0xE6524636),
  ),
  // Topográfico de Esri (calles + relieve), distinto del OpenTopoMap de arriba.
  MapStyle(
    name: 'Esri Topo',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri',
  ),
];
