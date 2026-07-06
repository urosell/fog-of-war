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

  /// Si no es null, el estilo se carga con una skin propia escrita desde cero
  /// (ver game_style.dart) en vez de tal cual lo sirve el proveedor. El valor
  /// identifica la skin ('game', 'corsair'); main.dart elige el loader. También
  /// hace de clave de caché: dos skins pueden compartir el mismo styleUri base.
  final String? customSkin;

  const MapStyle({
    required this.name,
    required this.nameKey,
    this.styleUri,
    this.urlTemplate,
    this.subdomains = const [],
    required this.attribution,
    this.colorMatrix,
    this.fogColor,
    this.customSkin,
  });

  /// ¿Es un estilo vectorial (style JSON) o raster (tiles PNG)?
  bool get isVector => styleUri != null;

  /// ¿Lleva skin propia (game_style.dart)?
  bool get custom => customSkin != null;

  /// Clave única de este estilo para cachés y keys de widgets. OJO: el styleUri
  /// NO vale (las skins custom comparten el mismo estilo base).
  String get cacheKey => customSkin ?? styleUri ?? urlTemplate ?? name;
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
const int kRasterFallbackIndex = 2;

/// Lista de estilos entre los que el jugador puede ir rotando. Los dos primeros
/// son skins vectoriales propias; los otros dos son raster de respaldo/variedad.
const List<MapStyle> kMapStyles = [
  // 0 — Juego: skin vectorial propia estilo Pokémon GO (ver game_style.dart). El
  //     styleUri es solo el estilo base del que se toman los proveedores de
  //     tiles; el aspecto lo define loadGameStyle(). Por defecto.
  MapStyle(
    name: 'Juego',
    nameKey: 'game',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'game',
  ),
  // 1 — Corsario: skin vectorial propia con la paleta "Assassin's Creed IV" de
  //     Snazzy Maps (tierra verde grisácea, calles gris verdoso, mar casi
  //     negro). Mismo dato y proveedores que "Juego", solo cambia la paleta.
  MapStyle(
    name: 'Corsario',
    nameKey: 'corsair',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'corsair',
    // Velo a juego con el tema: mismo alfa que kFogColor, tono verde-negro.
    fogColor: Color(0xEC1E2422),
  ),
  // 2 — Satélite: raster de imagen aérea (respaldo / variedad).
  MapStyle(
    name: 'Satélite',
    nameKey: 'satellite',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri, Maxar, Earthstar Geographics',
  ),
  // 3 — Oscuro: raster oscuro de CARTO (respaldo).
  MapStyle(
    name: 'Oscuro',
    nameKey: 'dark',
    urlTemplate: _darkUrl,
    subdomains: _cartoSubdomains,
    attribution: _cartoAttribution,
  ),
];
