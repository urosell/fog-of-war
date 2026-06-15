// Estilo de mapa "Juego" — skin propia estilo navegación clásica (referencia
// del usuario: mapa tipo Google Maps de antaño sobre el Eixample).
//
// NO es un recoloreo: es un estilo Mapbox GL escrito desde cero (capas, orden de
// pintado, jerarquía de calles, grosores, paleta y etiquetas) sobre el DATO
// vectorial de OpenStreetMap/OpenMapTiles que sirve OpenFreeMap. El dato (dónde
// están calles, manzanas, parques) viene del proveedor; el aspecto es 100%
// nuestro.
//
// Carácter del estilo:
//   • Tierra crema y manzanas caqui con borde (sensación de bloque).
//   • Jerarquía de calles por color: principales NARANJA, avenidas AMARILLAS y
//     calles menores BLANCAS, todas con su casing para que la retícula resalte.
//   • Parques verde vivo. Etiquetas de calle en cursiva.
//   • Flechas de sentido en calles de un solo sentido (si el renderer las pinta).
//
// Cómo encaja con vector_map_tiles: los PROVEEDORES (fuente "openmaptiles") y los
// SPRITES (atlas de iconos, p. ej. la flecha) se toman del estilo base de
// OpenFreeMap vía StyleReader; el TEMA (capas + pintado) lo construimos aquí.

import 'dart:convert';

import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

/// Estilo base del que tomamos proveedores de tiles y sprites.
const String kGameBaseStyleUri = 'https://tiles.openfreemap.org/styles/liberty';

// --- Paleta (navegación clásica cálida) ---
const String _land = '#ECE5D3'; // tierra: crema
const String _building = '#CBBA94'; // edificios: caqui/tostado (la masa del mapa)
const String _buildingLine = '#AE9C73'; // borde de edificio (relieve)
const String _park = '#82C957'; // parques: verde vivo
const String _parkLine = '#6BAE44'; // borde de parque
const String _grassDark = '#74BE4D'; // bosque/pitch: verde algo más hondo
const String _water = '#A6CBEA'; // agua: azul suave clásico
const String _roadPrimary = '#F77E4C'; // vías principales: naranja
const String _roadMajor = '#FBD24A'; // avenidas: amarillo
const String _roadMinor = '#FFFFFF'; // calles menores: blanco
const String _casingLight = '#FFFFFF'; // borde de avenidas amarillas/naranjas
const String _casingMinor = '#D8D1BE'; // borde de calles blancas (gris cálido)
const String _path = '#F0E9D6'; // senda peatonal
const String _rail = '#BCA682'; // vía de tren
const String _label = '#574B36'; // texto de calle
const String _labelStrong = '#3E3A2A'; // texto de barrio/zona
const String _halo = '#FFFFFF';

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

/// JSON del estilo (solo id + capas; las "sources"/sprites las aportan los
/// proveedores del estilo base).
Map<String, dynamic> _gameStyleJson() => {
      'id': 'fog_game',
      'version': 8,
      'layers': [
        // 1) Tierra.
        {
          'id': 'background',
          'type': 'background',
          'paint': {'background-color': _land},
        },
        // 2) Vegetación.
        {
          'id': 'wood',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'landcover',
          'filter': ['==', ['get', 'class'], 'wood'],
          'paint': {'fill-color': _grassDark, 'fill-opacity': 0.85},
        },
        {
          'id': 'grass',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'landcover',
          'filter': ['==', ['get', 'class'], 'grass'],
          'paint': {'fill-color': _park, 'fill-opacity': 0.85},
        },
        {
          'id': 'park',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'park',
          'paint': {'fill-color': _park, 'fill-opacity': 0.9},
        },
        {
          'id': 'park_outline',
          'type': 'line',
          'source': 'openmaptiles',
          'source-layer': 'park',
          'paint': {'line-color': _parkLine, 'line-width': 1.2},
        },
        {
          'id': 'pitch',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'landuse',
          'filter': ['==', ['get', 'class'], 'pitch'],
          'paint': {'fill-color': _grassDark},
        },
        // 3) Agua.
        {
          'id': 'water',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'water',
          'filter': ['!=', ['get', 'brunnel'], 'tunnel'],
          'paint': {'fill-color': _water},
        },
        {
          'id': 'waterway',
          'type': 'line',
          'source': 'openmaptiles',
          'source-layer': 'waterway',
          'paint': {'line-color': _water, 'line-width': _byZoom([12, 0.6, 20, 6])},
        },
        // 4) Edificios: bloque caqui con borde (desde z13, sin tope superior).
        {
          'id': 'building',
          'type': 'fill',
          'source': 'openmaptiles',
          'source-layer': 'building',
          'minzoom': 13,
          'paint': {
            'fill-color': _building,
            'fill-outline-color': _buildingLine,
          },
        },
        // 5) CASINGS (debajo de todas las calzadas): menor, avenida, principal.
        _roadLine('minor_casing', _minor, _casingMinor,
            [13, 1.4, 16, 8, 20, 22],
            minzoom: 13),
        _roadLine('major_casing', _major, _casingLight,
            [11, 2, 14, 6, 16, 13, 20, 26]),
        _roadLine('primary_casing', _primary, _casingLight,
            [9, 2.5, 14, 8, 16, 17, 20, 32]),
        // 6) CALZADAS: menor (blanca), avenida (amarilla), principal (naranja).
        _roadLine('minor', _minor, _roadMinor, [13, 0.8, 16, 6, 20, 18],
            minzoom: 13),
        _roadLine('major', _major, _roadMajor, [11, 1.2, 14, 4, 16, 10, 20, 20]),
        _roadLine('primary', _primary, _roadPrimary,
            [9, 1.5, 14, 6, 16, 13, 20, 26]),
        {
          'id': 'path',
          'type': 'line',
          'source': 'openmaptiles',
          'source-layer': 'transportation',
          'minzoom': 14,
          'filter': _classFilter(['path', 'pedestrian']),
          'paint': {
            'line-color': _path,
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
          'paint': {'line-color': _rail, 'line-width': _byZoom([13, 0.6, 20, 2.2])},
        },
        // 8) Etiquetas de calle (en cursiva, como la referencia).
        {
          'id': 'road_label',
          'type': 'symbol',
          'source': 'openmaptiles',
          'source-layer': 'transportation_name',
          'minzoom': 14,
          'layout': {
            'symbol-placement': 'line',
            'text-field': ['coalesce', ['get', 'name:latin'], ['get', 'name']],
            'text-font': ['Noto Sans Italic'],
            'text-size': _byZoom([14, 11, 18, 13], base: 1),
          },
          'paint': {
            'text-color': _label,
            'text-halo-color': _halo,
            'text-halo-width': 1.4,
          },
        },
        // 9) Etiquetas de barrio / zona.
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
            'text-color': _labelStrong,
            'text-halo-color': _halo,
            'text-halo-width': 1.6,
          },
        },
      ],
    };

/// Construye el estilo de juego: proveedores del estilo base + tema propio.
Future<Style> loadGameStyle() async {
  final base = await StyleReader(uri: kGameBaseStyleUri).read();
  final json = _gameStyleJson();
  // Versionamos el tema con un hash del propio estilo: cada cambio de paleta o
  // capas invalida la caché de tiles ya renderizados de vector_map_tiles.
  final version = jsonEncode(json['layers']).hashCode.toRadixString(16);
  json['metadata'] = {'version': version};
  final theme = vtr.ThemeReader().read(json);
  return Style(
    name: 'game',
    theme: theme,
    providers: base.providers,
    sprites: base.sprites,
  );
}
