// Estilos de mapa base disponibles en el juego.
//
// Hay dos tipos de estilo:
//   • VECTORIAL: se describe con un "style JSON" (Mapbox GL) que vector_map_tiles
//     renderiza nítido a cualquier zoom y con colores personalizables. Es el look
//     moderno y "agradable" que buscamos. Usamos OpenFreeMap: gratis, sin clave
//     de API y sin límites de uso.
//   • RASTER: imágenes PNG servidas por un proveedor de tiles. Se ven algo
//     borrosas entre niveles de zoom, pero no dependen del render por GPU. Los
//     mantenemos como red de seguridad por si el render vectorial diera problemas
//     en algún dispositivo.
//
// Todos estos estilos son de uso libre. Antes de publicar hay que mostrar la
// atribución (campo [attribution]) visible en pantalla, que es obligatoria.

import 'dart:ui' show Color;

/// Un estilo de mapa: nombre legible + de dónde se obtiene su aspecto.
class MapStyle {
  /// Nombre por defecto (fallback si no hay traducción). Ver [nameKey].
  final String name;

  /// Clave estable para localizar el nombre (ver localizedMapStyleName). Es
  /// estable aunque se reordene la lista, a diferencia de un índice.
  final String nameKey;

  /// Estilo VECTORIAL: URL del "style JSON" (Mapbox GL). Si no es null, este
  /// estilo se renderiza con vector_map_tiles y [urlTemplate] se ignora.
  final String? styleUri;

  /// Estilo RASTER: plantilla de URL de los tiles, con {z}/{x}/{y} (y opcional
  /// {s}). Solo se usa cuando [styleUri] es null.
  final String? urlTemplate;

  /// Subdominios para repartir la carga (solo raster, si la URL tiene {s}).
  final List<String> subdomains;

  /// Texto de atribución obligatorio para este proveedor.
  final String attribution;

  /// Matriz de color 4x5 opcional (20 valores) para teñir los tiles RASTER.
  /// Null = sin filtro. (Los estilos vectoriales se tiñen desde su style JSON.)
  final List<double>? colorMatrix;

  /// Color del velo de niebla a juego con este estilo. Null = usa el color por
  /// defecto del juego (gris azulado). Conviene mantener la misma opacidad para
  /// que la sensación de "cuánto tapa la niebla" no cambie entre estilos.
  final Color? fogColor;

  /// Si es true, el estilo se carga con una skin propia escrita desde cero
  /// (ver game_style.dart) en vez de tal cual lo sirve el proveedor.
  final bool custom;

  const MapStyle({
    required this.name,
    required this.nameKey,
    this.styleUri,
    this.urlTemplate,
    this.subdomains = const [],
    required this.attribution,
    this.colorMatrix,
    this.fogColor,
    this.custom = false,
  });

  /// ¿Es un estilo vectorial (style JSON) o raster (tiles PNG)?
  bool get isVector => styleUri != null;
}

// --- Estilo vectorial (OpenFreeMap, recoloreado) ---
const String _ofmAttribution =
    '© OpenStreetMap, OpenFreeMap, OpenMapTiles';

// --- Tiles raster de respaldo (CARTO oscuro) ---
const String _darkUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
const List<String> _cartoSubdomains = ['a', 'b', 'c', 'd'];
const String _cartoAttribution = '© OpenStreetMap, © CARTO';

/// Estilo por defecto al arrancar (índice en kMapStyles): "Juego", la skin
/// vectorial propia estilo videojuego.
const int kDefaultStyleIndex = 0;

/// Índice del primer estilo RASTER de la lista, usado como respaldo automático
/// si el estilo vectorial no consigue cargar.
const int kRasterFallbackIndex = 1;

/// Lista de estilos entre los que el jugador puede ir rotando. El primero es el
/// vectorial cálido (por defecto); los otros dos son raster de respaldo/variedad.
const List<MapStyle> kMapStyles = [
  // 0 — Juego: skin vectorial propia estilo Pokémon GO (ver game_style.dart). El
  //     styleUri es solo el estilo base del que se toman los proveedores de
  //     tiles; el aspecto lo define loadGameStyle(). Por defecto.
  MapStyle(
    name: 'Juego',
    nameKey: 'game',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    custom: true,
  ),
  // 1 — Satélite: raster de imagen aérea (respaldo / variedad).
  MapStyle(
    name: 'Satélite',
    nameKey: 'satellite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri, Maxar, Earthstar Geographics',
  ),
  // 2 — Oscuro: raster oscuro de CARTO (respaldo).
  MapStyle(
    name: 'Oscuro',
    nameKey: 'dark',
    urlTemplate: _darkUrl,
    subdomains: _cartoSubdomains,
    attribution: _cartoAttribution,
  ),
];
