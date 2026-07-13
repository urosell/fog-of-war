// Estilo de mapa "Juego" — skins propias sobre el dato vectorial de
// OpenStreetMap/OpenMapTiles que sirve OpenFreeMap.
//
// NO es un recoloreo: es un estilo Mapbox GL escrito desde cero (capas, orden de
// pintado, jerarquía de calles, grosores, paleta y etiquetas). El dato (dónde
// están calles, manzanas, parques) viene del proveedor; el aspecto es 100%
// nuestro. La ESTRUCTURA de capas es común a todas las skins; cada skin es una
// paleta (_GamePalette) que la tiñe:
//
//   • CLÁSICA (loadGameStyle) — navegación clásica cálida (referencia del
//     usuario: mapa tipo Google Maps de antaño sobre el Eixample). Tierra crema
//     y manzanas caqui, jerarquía de calles naranja/amarillo/blanco, parques
//     verde vivo, etiquetas de calle en cursiva.
//
//   • CORSARIO (loadCorsairStyle) — paleta del estilo "Assassin's Creed IV" de
//     Snazzy Maps (snazzymaps.com/style/72543): tierra verde grisácea apagada,
//     calles gris verdoso en una sola familia tonal y agua casi negra. Ambiente
//     naval nocturno. Fiel a la referencia, las calles NO llevan etiqueta; los
//     barrios sí (atenuados), para no perder la orientación jugando.
//
// Cómo encaja con vector_map_tiles: los PROVEEDORES (fuente "openmaptiles") y los
// SPRITES (atlas de iconos, p. ej. la flecha) se toman del estilo base de
// OpenFreeMap vía StyleReader; el TEMA (capas + pintado) lo construimos aquí.

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

/// Estilo base del que tomamos proveedores de tiles y sprites.
const String kGameBaseStyleUri = 'https://tiles.openfreemap.org/styles/liberty';

// Paleta de una skin: los colores que tiñen la estructura de capas común, más
// el interruptor de etiquetas de calle (hay skins que no las llevan).
class _GamePalette {
  final String land; // tierra / fondo
  final String building; // edificios y manzanas de uso urbano
  final String park; // parques y hierba
  final String parkLine; // borde de parque
  final String grassDark; // bosque / pistas deportivas
  final String water; // mar, ríos
  final String roadPrimary; // vías principales
  final String roadMajor; // avenidas
  final String roadMinor; // calles menores
  final String casingLight; // borde de avenidas/principales
  final String casingMinor; // borde de calles menores
  final String path; // senda peatonal
  final String rail; // vía de tren
  final String label; // texto de calle
  final String labelStrong; // texto de barrio/zona
  final String halo; // halo de los textos
  final bool roadLabels; // ¿etiquetas de calle?

  const _GamePalette({
    required this.land,
    required this.building,
    required this.park,
    required this.parkLine,
    required this.grassDark,
    required this.water,
    required this.roadPrimary,
    required this.roadMajor,
    required this.roadMinor,
    required this.casingLight,
    required this.casingMinor,
    required this.path,
    required this.rail,
    required this.label,
    required this.labelStrong,
    required this.halo,
    this.roadLabels = true,
  });
}

// --- Skin clásica (navegación clásica cálida, más saturada y con cuerpo) ---
const _classic = _GamePalette(
  land: '#D4C18C', // tierra: crema dorada más honda (menos clara)
  building: '#B8975A', // edificios: caqui tostado oscuro (la masa)
  park: '#5DB52E', // parques: verde vivo saturado
  parkLine: '#43881E', // borde de parque
  grassDark: '#4DA522', // bosque/pitch: verde algo más hondo
  water: '#5AA6E0', // agua: azul saturado clásico
  roadPrimary: '#F25E22', // vías principales: naranja vivo
  roadMajor: '#F5B610', // avenidas: amarillo dorado
  roadMinor: '#F2EBD8', // calles menores: crema claro (no blanco puro)
  casingLight: '#FBF6E8', // borde de avenidas amarillas/naranjas
  casingMinor: '#BCAC80', // borde de calles blancas (gris cálido)
  path: '#E0CFA4', // senda peatonal
  rail: '#9C7E4E', // vía de tren
  label: '#574B36', // texto de calle
  labelStrong: '#3E3A2A', // texto de barrio/zona
  halo: '#FFFFFF',
);

// --- Skin corsario (paleta Assassin's Creed IV de Snazzy Maps) ---
// Referencia: tierra #4d6059, calles #7f8d89, agua #24282b. La jerarquía de
// calles se mantiene con variaciones sutiles del mismo gris verdoso (la
// referencia las pinta todas iguales; el ancho ya diferencia).
const _corsair = _GamePalette(
  land: '#4D6059', // tierra: verde grisáceo apagado (el de la referencia)
  building: '#46564F', // edificios: un punto más oscuros que la tierra
  park: '#556D58', // parques: verde apenas más claro (guiño jugable)
  parkLine: '#415842', // borde de parque
  grassDark: '#4E6350', // bosque/pitch
  water: '#24282B', // agua: casi negra (el mar nocturno de la referencia)
  roadPrimary: '#8E9C97', // principales: el gris de la referencia, aclarado
  roadMajor: '#7F8D89', // avenidas: el gris verdoso de la referencia
  roadMinor: '#71807B', // menores: el mismo, oscurecido
  casingLight: '#3C4843', // borde oscuro: las calles flotan sobre la tierra
  casingMinor: '#44514B',
  path: '#62716B', // senda peatonal
  rail: '#414E48', // vía de tren
  label: '#AEBDB4', // (sin uso: sin etiquetas de calle)
  labelStrong: '#AEBDB4', // barrios: claro atenuado sobre el fondo oscuro
  halo: '#303B36', // halo oscuro (el blanco chillaría en este tema)
  roadLabels: false, // fiel a la referencia: calles sin nombre
);

/// Interpolación exponencial por zoom: [stops] = [z0,v0, z1,v1, ...].
List<dynamic> _byZoom(List<num> stops, {double base = 1.2}) =>
    ['interpolate', ['exponential', base], ['zoom'], ...stops];

// Clases de calle por nivel.
const List<String> _primary = ['motorway', 'trunk', 'primary'];
const List<String> _major = ['secondary', 'tertiary'];
const List<String> _minor = ['minor', 'service'];

List<dynamic> _classFilter(List<String> classes) =>
    ['match', ['get', 'class'], classes, true, false];

/// Una capa de línea de calle (casing o calzada).
Map<String, dynamic> _roadLine(
  String id,
  List<String> classes,
  String color,
  List<num> widthStops, {
  int? minzoom,
}) =>
    {
      'id': id,
      'type': 'line',
      'source': 'openmaptiles',
      'source-layer': 'transportation',
      'minzoom': ?minzoom,
      'filter': _classFilter(classes),
      'layout': {'line-join': 'round', 'line-cap': 'round'},
      'paint': {'line-color': color, 'line-width': _byZoom(widthStops)},
    };

/// Interruptores de partes CARAS del theme, para los experimentos de
/// rendimiento (tool/perf): permiten medir cuánto cuesta cada una. El estilo
/// de producción los lleva todos encendidos.
class GameThemeTweaks {
  /// Capa building_dilate (engordado de edificios, lo más caro del theme).
  final bool buildingDilate;

  /// Capas symbol (etiquetas de calle y de barrio, layout de texto).
  final bool labels;

  /// Etiquetas de calle "aligeradas": solo vías mayores y desde z15. El
  /// layout de texto por tile resultó ser el mayor coste del theme (medido);
  /// esto lo recorta manteniendo las etiquetas que se ven al jugar (z16 el
  /// colisionador ya descarta casi todas las menores).
  final bool liteRoadLabels;

  const GameThemeTweaks({
    this.buildingDilate = true,
    this.labels = true,
    this.liteRoadLabels = false,
  });
}

/// JSON del estilo (solo id + capas; las "sources"/sprites las aportan los
/// proveedores del estilo base). La estructura es común; [p] la tiñe y [t]
/// permite apagar partes caras en los experimentos de rendimiento.
Map<String, dynamic> _gameStyleJson(String id, _GamePalette p,
        [GameThemeTweaks t = const GameThemeTweaks()]) => {
      'id': id,
      'version': 8,
      'layers': [
        // 1) Tierra.
        {
          'id': 'background',
          'type': 'background',
          'paint': {'background-color': p.land},
        },
        // 1b) Manzanas sólidas: relleno de uso de suelo urbano (residencial,
        // comercial, industrial…) del mismo color que los edificios. Va debajo
        // de vegetación/agua/calles, así rellena la manzana ENTERA (incluidos
        // los patios interiores) y la deja como un bloque limpio, sin los huecos
        // color tierra que dejaban los edificios sueltos.
        {
          'id': 'landuse_urban',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'landuse',
          'minzoom': 11,
          'filter': ['match', ['get', 'class'],
              ['residential', 'commercial', 'industrial', 'retail', 'garages'],
              true, false],
          'paint': {'fill-color': p.building},
        },
        // 2) Vegetación.
        {
          'id': 'wood',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'landcover',
          'filter': ['==', ['get', 'class'], 'wood'],
          'paint': {'fill-color': p.grassDark, 'fill-opacity': 0.85},
        },
        {
          'id': 'grass',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'landcover',
          'filter': ['==', ['get', 'class'], 'grass'],
          'paint': {'fill-color': p.park, 'fill-opacity': 0.85},
        },
        {
          'id': 'park',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'park',
          'paint': {'fill-color': p.park, 'fill-opacity': 0.9},
        },
        {
          'id': 'park_outline',
          'type': 'line',
          'source': 'openmaptiles',
          'source-layer': 'park',
          'paint': {'line-color': p.parkLine, 'line-width': 1.2},
        },
        {
          'id': 'pitch',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'landuse',
          'filter': ['==', ['get', 'class'], 'pitch'],
          'paint': {'fill-color': p.grassDark},
        },
        // 3) Agua.
        {
          'id': 'water',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'water',
          'filter': ['!=', ['get', 'brunnel'], 'tunnel'],
          'paint': {'fill-color': p.water},
        },
        {
          'id': 'waterway',
          'type': 'line',
          'source': 'openmaptiles',
          'source-layer': 'waterway',
          'paint': {
            'line-color': p.water,
            'line-width': _byZoom([12, 0.6, 20, 6]),
          },
        },
        // 4) Edificios: masa sólida por manzana (desde z13, sin tope superior).
        // SIN borde por edificio: los edificios contiguos del mismo color se
        // fusionan en un bloque limpio (estilo juego), evitando el ruido de
        // dibujar cada parcela del Eixample con su línea.
        {
          'id': 'building',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'building',
          'minzoom': 13,
          'paint': {
            'fill-color': p.building,
          },
        },
        // 4b) Dilatación de edificios: misma capa pintada como línea gruesa del
        // color del edificio. Engorda cada polígono, fusiona los edificios
        // contiguos y cierra los huecos pequeños entre ellos. Así las manzanas
        // SIN dato de uso de suelo (que solo tienen edificios sueltos) quedan
        // casi tan macizas como las que sí lo tienen → aspecto homogéneo.
        //
        // RENDIMIENTO: esta capa es lo más caro del tema (miles de polígonos
        // por tile con línea gruesa). Por eso arranca en z15 (a z13-14 un tile
        // abarca media ciudad y la manzana ya la pinta landuse_urban) y usa
        // join 'bevel' (el 'round' es mucho más caro de teselar; los anillos
        // cerrados no pintan line-cap, así que ni se declara). Los anchos
        // empalman con los que había: a partir de z15 se ve igual.
        if (t.buildingDilate)
          {
            'id': 'building_dilate',
            'type': 'line',
            'source': 'openmaptiles',
            'source-layer': 'building',
            'minzoom': 15,
            'layout': {'line-join': 'bevel'},
            'paint': {
              'line-color': p.building,
              'line-width': _byZoom([15, 3.5, 16, 5, 19, 12]),
            },
          },
        // 5) CASINGS (debajo de todas las calzadas): menor, avenida, principal.
        _roadLine('minor_casing', _minor, p.casingMinor,
            [13, 1.4, 16, 8, 20, 22],
            minzoom: 13),
        _roadLine('major_casing', _major, p.casingLight,
            [11, 1.4, 14, 4.2, 16, 9.5, 20, 19]),
        _roadLine('primary_casing', _primary, p.casingLight,
            [9, 1.8, 14, 5.6, 16, 12, 20, 24]),
        // 6) CALZADAS: menor, avenida, principal.
        _roadLine('minor', _minor, p.roadMinor, [13, 0.8, 16, 6, 20, 18],
            minzoom: 13),
        _roadLine(
            'major', _major, p.roadMajor, [11, 0.9, 14, 2.8, 16, 7, 20, 14]),
        _roadLine('primary', _primary, p.roadPrimary,
            [9, 1.1, 14, 4.2, 16, 9, 20, 18]),
        {
          'id': 'path',
          'type': 'line',
          'source': 'openmaptiles',
          'source-layer': 'transportation',
          'minzoom': 14,
          'filter': _classFilter(['path', 'pedestrian']),
          'paint': {
            'line-color': p.path,
            'line-dasharray': [2, 1.5],
            'line-width': _byZoom([14, 1, 20, 8]),
          },
        },
        // 7) Vías de tren.
        {
          'id': 'rail',
          'type': 'line',
          'source': 'openmaptiles',
          'source-layer': 'transportation',
          'minzoom': 13,
          'filter': ['==', ['get', 'class'], 'rail'],
          'paint': {
            'line-color': p.rail,
            'line-width': _byZoom([13, 0.6, 20, 2.2]),
          },
        },
        // 8) Etiquetas de calle (en cursiva, como la referencia clásica). Hay
        // skins sin ellas (corsario). En modo "lite" solo se etiquetan las
        // vías mayores y desde z15: menos layout de texto por tile (el mayor
        // coste medido del theme) con impacto visual mínimo al jugar.
        if (t.labels && p.roadLabels)
          {
            'id': 'road_label',
            'type': 'symbol',
            'source': 'openmaptiles',
            'source-layer': 'transportation_name',
            'minzoom': t.liteRoadLabels ? 15 : 14,
            if (t.liteRoadLabels)
              'filter': _classFilter(
                  ['motorway', 'trunk', 'primary', 'secondary', 'tertiary']),
            'layout': {
              'symbol-placement': 'line',
              'text-field': ['coalesce', ['get', 'name:latin'], ['get', 'name']],
              'text-font': ['Noto Sans Italic'],
              'text-size': _byZoom([14, 11, 18, 13], base: 1),
            },
            'paint': {
              'text-color': p.label,
              'text-halo-color': p.halo,
              'text-halo-width': 1.4,
            },
          },
        // 9) Etiquetas de barrio / zona.
        if (t.labels)
        {
          'id': 'place_label',
          'type': 'symbol',
          'source': 'openmaptiles',
          'source-layer': 'place',
          'filter': _classFilter(
              ['suburb', 'neighbourhood', 'quarter', 'town', 'village']),
          'layout': {
            'text-field': ['coalesce', ['get', 'name:latin'], ['get', 'name']],
            'text-font': ['Noto Sans Bold'],
            'text-size': _byZoom([12, 11, 16, 15], base: 1),
            'text-transform': 'uppercase',
            'text-letter-spacing': 0.05,
          },
          'paint': {
            'text-color': p.labelStrong,
            'text-halo-color': p.halo,
            'text-halo-width': 1.6,
          },
        },
      ],
    };

// Construye un estilo: proveedores del estilo base + tema propio de la skin.
Future<Style> _loadSkin(String id, _GamePalette palette,
    [GameThemeTweaks tweaks = const GameThemeTweaks()]) async {
  final base = await StyleReader(uri: kGameBaseStyleUri).read();
  final json = _gameStyleJson(id, palette, tweaks);
  // Versionamos el tema con un hash del propio estilo: cada cambio de paleta o
  // capas invalida la caché de tiles ya renderizados de vector_map_tiles.
  final version = jsonEncode(json['layers']).hashCode.toRadixString(16);
  json['metadata'] = {'version': version};
  final theme = vtr.ThemeReader().read(json);
  return Style(
    name: id,
    theme: theme,
    providers: base.providers,
    sprites: base.sprites,
  );
}

/// Skin clásica del estilo "Juego" (navegación clásica cálida). Lleva las
/// etiquetas de calle "lite" (solo vías mayores, desde z15): medido en
/// tool/perf, el layout de texto era el mayor coste del primer render de cada
/// tile y esto lo recorta ~25% con impacto visual mínimo al jugar.
Future<Style> loadGameStyle() =>
    _loadSkin('fog_game', _classic, const GameThemeTweaks(liteRoadLabels: true));

/// Skin "Corsario" (paleta Assassin's Creed IV).
Future<Style> loadCorsairStyle() => _loadSkin('fog_corsair', _corsair);

/// Variantes de la skin clásica para los experimentos de rendimiento
/// (tool/perf; solo se alcanzan con --dart-define=MAP_PERF_EXPERIMENTS=true).
/// OJO: cada variante lleva su propio id de theme aunque el aspecto no cambie
/// (exp_c2, exp_c6…): la caché de tiles renderizados se namespacia por
/// id+versión y así la pasada "fría" del test no hereda la caché de otra
/// variante. Los knobs (concurrency, maximumZoom…) van en MapStyle.tuning,
/// no aquí.
/// Solo para tests (sin red): el JSON del theme de la skin clásica.
@visibleForTesting
Map<String, dynamic> classicThemeJsonForTest(
        [GameThemeTweaks tweaks = const GameThemeTweaks()]) =>
    _gameStyleJson('test_classic', _classic, tweaks);

/// Solo para tests (sin red): el JSON del theme de la skin corsario.
@visibleForTesting
Map<String, dynamic> corsairThemeJsonForTest(
        [GameThemeTweaks tweaks = const GameThemeTweaks()]) =>
    _gameStyleJson('test_corsair', _corsair, tweaks);

Future<Style> loadExperimentStyle(String skin) => switch (skin) {
      'exp_nodilate' => _loadSkin('fog_exp_nodilate', _classic,
          const GameThemeTweaks(buildingDilate: false)),
      'exp_nolabels' => _loadSkin(
          'fog_exp_nolabels', _classic, const GameThemeTweaks(labels: false)),
      'exp_bare' => _loadSkin('fog_exp_bare', _classic,
          const GameThemeTweaks(buildingDilate: false, labels: false)),
      // Theme "Juego" intacto: solo cambia el espacio de caché y el tuning.
      'exp_c2' => _loadSkin('fog_exp_c2', _classic),
      'exp_c6' => _loadSkin('fog_exp_c6', _classic),
      'exp_mz17' => _loadSkin('fog_exp_mz17', _classic),
      'exp_off1' => _loadSkin('fog_exp_off1', _classic),
      'exp_cache' => _loadSkin('fog_exp_cache', _classic),
      // Candidatas a config de producción: etiquetas lite + tuning combinado
      // (el tuning va en MapStyle.tuning; aquí solo el theme y el id de caché).
      'exp_opt2' => _loadSkin('fog_exp_opt2', _classic,
          const GameThemeTweaks(liteRoadLabels: true)),
      'exp_opt4' => _loadSkin('fog_exp_opt4', _classic,
          const GameThemeTweaks(liteRoadLabels: true)),
      _ => throw ArgumentError('Skin de experimento desconocida: $skin'),
    };
