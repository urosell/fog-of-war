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

/// Ajustes finos del VectorTileLayer (vector_map_tiles) para un estilo
/// vectorial. Cualquier campo a null usa el default del paquete. Se usan en
/// los experimentos de rendimiento (tool/perf) y, tras medir, en la
/// configuración de producción.
class VectorTuning {
  /// Nº de isolates para parsear tiles; también limita (×2) cuántos tiles se
  /// renderizan a la vez en el hilo de UI. Default del paquete: 4.
  final int? concurrency;

  /// Zoom máximo con render propio; por encima se escala la imagen (como un
  /// raster con maxNativeZoom). Default del paquete: 18.
  final double? maximumZoom;

  /// Offset de zoom del dato: -1 = renderizar cada tile con dato de un nivel
  /// menos (más barato, menos detalle). Default: 0.
  final int? zoomOffset;

  /// Caché en memoria del dato crudo de tiles, en bytes. Default: 10 MB.
  final int? memoryTileCacheMaxSize;

  /// Caché en memoria de tiles ya parseados, en nº de tiles (<100).
  /// Default: 20.
  final int? memoryTileDataCacheMaxSize;

  /// Caché de disco (dato crudo + imágenes renderizadas), en bytes.
  /// Default: 50 MB.
  final int? fileCacheMaximumSizeInBytes;

  /// Caché de textos ya maquetados (el layout de etiquetas se repite entre
  /// tiles: los nombres de calle cruzan varios). Default: 100 entradas.
  final int? textCacheMaxSize;

  const VectorTuning({
    this.concurrency,
    this.maximumZoom,
    this.zoomOffset,
    this.memoryTileCacheMaxSize,
    this.memoryTileDataCacheMaxSize,
    this.fileCacheMaximumSizeInBytes,
    this.textCacheMaxSize,
  });
}

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

  /// Ajustes del VectorTileLayer para este estilo (solo vectoriales).
  /// Null = defaults de vector_map_tiles.
  final VectorTuning? tuning;

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
    this.tuning,
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

/// Ajustes de producción del render vectorial, elegidos midiendo (tool/perf,
/// 2026-07-12): concurrency se queda en el default 4 (2 mejora el primer
/// render pero degrada el mapa ya cacheado); caché de texto ampliada (los
/// nombres de calle se repiten entre tiles); cachés de memoria generosas; y
/// 150 MB de disco para que la ciudad ya renderizada persista entre sesiones
/// (tras la primera visita, el mapa pinta como un raster puro).
const VectorTuning kProductionVectorTuning = VectorTuning(
  textCacheMaxSize: 512,
  memoryTileCacheMaxSize: 32 * 1024 * 1024,
  memoryTileDataCacheMaxSize: 60,
  fileCacheMaximumSizeInBytes: 150 * 1024 * 1024,
);

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
    tuning: kProductionVectorTuning,
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
    tuning: kProductionVectorTuning,
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

// --- Experimentos de rendimiento (tool/perf) ---
//
// Variantes del estilo "Juego" para aislar el coste de cada parte del render.
// Solo existen compilando con --dart-define=MAP_PERF_EXPERIMENTS=true: en el
// binario normal kActiveMapStyles == kMapStyles y nada de esto entra en el
// ciclo de estilos del jugador. Cada variante con skin propia usa un id de
// theme DISTINTO (ver game_style.dart): la caché de tiles renderizados se
// namespacia por id+versión y así ninguna variante hereda la caché de otra
// (la pasada "fría" del test es fría de verdad).

/// ¿Binario con los estilos de experimento? (--dart-define)
const bool kMapPerfExperiments =
    bool.fromEnvironment('MAP_PERF_EXPERIMENTS');

/// Estilos extra de experimento. El prefijo 'exp_' en customSkin los enruta al
/// loader de variantes de game_style.dart (loadExperimentStyle).
const List<MapStyle> kExperimentStyles = [
  // ¿Cuánto cuesta la capa building_dilate ("lo más caro del tema")?
  MapStyle(
    name: 'Exp: sin dilate',
    nameKey: 'exp_nodilate',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_nodilate',
  ),
  // ¿Cuánto cuesta el layout de texto (etiquetas de calle y barrio)?
  MapStyle(
    name: 'Exp: sin etiquetas',
    nameKey: 'exp_nolabels',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_nolabels',
  ),
  // Suelo teórico del theme propio: sin dilate NI etiquetas.
  MapStyle(
    name: 'Exp: theme mínimo',
    nameKey: 'exp_bare',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_bare',
  ),
  // "Sin skin": el estilo Liberty completo tal cual lo sirve OpenFreeMap.
  // ¿Nuestra skin es más cara o más barata que un estilo de referencia?
  MapStyle(
    name: 'Exp: Liberty',
    nameKey: 'exp_liberty',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
  ),
  // Knobs del VectorTileLayer sobre el theme Juego SIN tocar (cada uno con su
  // propio espacio de caché vía el sufijo del id del theme).
  MapStyle(
    name: 'Exp: concurrency 2',
    nameKey: 'exp_c2',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_c2',
    tuning: VectorTuning(concurrency: 2),
  ),
  MapStyle(
    name: 'Exp: concurrency 6',
    nameKey: 'exp_c6',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_c6',
    tuning: VectorTuning(concurrency: 6),
  ),
  MapStyle(
    name: 'Exp: maxZoom 17',
    nameKey: 'exp_mz17',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_mz17',
    tuning: VectorTuning(maximumZoom: 17),
  ),
  MapStyle(
    name: 'Exp: tileOffset -1',
    nameKey: 'exp_off1',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_off1',
    tuning: VectorTuning(zoomOffset: -1),
  ),
  MapStyle(
    name: 'Exp: cachés ampliadas',
    nameKey: 'exp_cache',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_cache',
    tuning: VectorTuning(
      memoryTileCacheMaxSize: 32 * 1024 * 1024,
      memoryTileDataCacheMaxSize: 80,
      fileCacheMaximumSizeInBytes: 150 * 1024 * 1024,
    ),
  ),
  // Candidatas a config de producción (Fase 2): combinan las palancas
  // ganadoras del barrido — etiquetas de calle lite (el mayor coste del
  // theme), caché de texto ampliada y cachés generosas — y difieren solo en
  // concurrency (2 dio la mejor pasada fría pero con una regresión sospechosa
  // en caliente; head-to-head contra 4 para decidir).
  MapStyle(
    name: 'Exp: opt c2',
    nameKey: 'exp_opt2',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_opt2',
    tuning: VectorTuning(
      concurrency: 2,
      textCacheMaxSize: 512,
      memoryTileCacheMaxSize: 32 * 1024 * 1024,
      memoryTileDataCacheMaxSize: 60,
      fileCacheMaximumSizeInBytes: 150 * 1024 * 1024,
    ),
  ),
  MapStyle(
    name: 'Exp: opt c4',
    nameKey: 'exp_opt4',
    styleUri: 'https://tiles.openfreemap.org/styles/liberty',
    attribution: _ofmAttribution,
    customSkin: 'exp_opt4',
    tuning: VectorTuning(
      concurrency: 4,
      textCacheMaxSize: 512,
      memoryTileCacheMaxSize: 32 * 1024 * 1024,
      memoryTileDataCacheMaxSize: 60,
      fileCacheMaximumSizeInBytes: 150 * 1024 * 1024,
    ),
  ),
];

/// Estilos activos en este binario: los del juego y, si el binario es de
/// experimentos, también las variantes de medición.
final List<MapStyle> kActiveMapStyles = kMapPerfExperiments
    ? [...kMapStyles, ...kExperimentStyles]
    : kMapStyles;
