// Estilos de mapa base disponibles en el juego.
//
// Cada estilo es simplemente un servidor de "tiles" (las imágenes del mapa) con
// un aspecto distinto. Cambiar de estilo = cambiar la URL del TileLayer.
//
// Todos estos estilos son de uso libre y NO necesitan clave de API, así que
// valen para probar y para el MVP. Antes de publicar hay que mostrar la
// atribución (campo [attribution]) visible en pantalla, que es obligatoria.

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

  const MapStyle({
    required this.name,
    required this.urlTemplate,
    this.subdomains = const [],
    required this.attribution,
  });
}

/// Lista de estilos entre los que el jugador puede ir rotando.
const List<MapStyle> kMapStyles = [
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
];
