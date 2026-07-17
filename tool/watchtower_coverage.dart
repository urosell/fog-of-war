// Cobertura de las atalayas sobre el pozo de POIs (herramienta de contenido).
//
// Uso: dart run tool/watchtower_coverage.dart
//
// Descarga el contenido VIVO de la Google Sheet (pestañas POIs y Watchtowers,
// las mismas que lee la app) y, para cada atalaya, lista qué POIs caen dentro
// de su radio de avistado, con la distancia; al final, los POIs que NINGUNA
// atalaya cubre. Sirve para colocar atalayas nuevas y ajustar radios sin ir a
// ciegas (el círculo del modo admin enseña lo mismo sobre el mapa, esto da los
// números). Sin red (o sin pestaña Watchtowers), usa las listas semilla
// embebidas, avisando.
//
// No reutiliza lib/content/content_parser.dart porque ese importa Flutter
// (Color) y esto corre en la VM de Dart pura; el parseo de aquí es el mínimo
// que necesita la cuenta (id, name, lat, lon, category/radius_m).

// ignore_for_file: avoid_print  (herramienta de consola: imprimir es su trabajo)

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:fog_of_war/content/content_config.dart';
import 'package:fog_of_war/poi/poi.dart';
import 'package:fog_of_war/watchtower/watchtower.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<void> main() async {
  final (pois, towers) = await _loadContent();

  const distance = Distance();
  final cubiertos = <String>{};

  for (final tower in towers) {
    final avistados = <(Poi, double)>[
      for (final poi in pois)
        if (distance(tower.location, poi.location) <= tower.revealRadiusMeters)
          (poi, distance(tower.location, poi.location).toDouble()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    print('${tower.name} (${tower.revealRadiusMeters.round()} m): '
        '${avistados.length} POIs');
    for (final (poi, metros) in avistados) {
      cubiertos.add(poi.id);
      print('   ${metros.round().toString().padLeft(4)} m  ${poi.id}');
    }
  }

  final huerfanos = pois.where((p) => !cubiertos.contains(p.id)).toList();
  print('\nSin cubrir por ninguna atalaya: ${huerfanos.length}');
  for (final poi in huerfanos) {
    print('   ${poi.id} (${poi.category.label})');
  }
}

/// Descarga POIs y atalayas de la hoja; ante cualquier fallo, la semilla.
Future<(List<Poi>, List<Watchtower>)> _loadContent() async {
  final id = kSpreadsheetId;
  if (id == null) {
    print('(kSpreadsheetId es null: usando el contenido semilla)\n');
    return (kBarcelonaPois, kBarcelonaWatchtowers);
  }

  List<Poi> pois;
  try {
    pois = _parsePois(await _get(sheetCsvUrl(id, kPoisSheetName)));
    print('POIs de la hoja: ${pois.length}');
  } catch (e) {
    print('(no pude descargar la pestaña $kPoisSheetName: $e; '
        'usando la semilla)');
    pois = kBarcelonaPois;
  }

  List<Watchtower> towers;
  try {
    towers = _parseWatchtowers(await _get(sheetCsvUrl(id, kWatchtowersSheetName)));
    print('Atalayas de la hoja: ${towers.length}\n');
  } catch (e) {
    print('(pestaña $kWatchtowersSheetName no disponible: $e; '
        'usando la semilla)\n');
    towers = kBarcelonaWatchtowers;
  }
  return (pois, towers);
}

Future<String> _get(String url) async {
  final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
  return res.body;
}

List<Poi> _parsePois(String csv) {
  final rows = _rows(csv);
  final col = _header(rows.first);
  return [
    for (final row in rows.skip(1))
      if (_cell(row, col, 'id').isNotEmpty &&
          double.tryParse(_cell(row, col, 'lat')) != null &&
          double.tryParse(_cell(row, col, 'lon')) != null)
        Poi(
          id: _cell(row, col, 'id'),
          name: _cell(row, col, 'name'),
          location: LatLng(double.parse(_cell(row, col, 'lat')),
              double.parse(_cell(row, col, 'lon'))),
          category: PoiCategory.values.firstWhere(
              (c) => c.name == _cell(row, col, 'category').toLowerCase(),
              orElse: () => PoiCategory.plaza),
        ),
  ];
}

List<Watchtower> _parseWatchtowers(String csv) {
  final rows = _rows(csv);
  final col = _header(rows.first);
  // La misma guarda que content_parser.dart: si falta la pestaña, gviz
  // devuelve la primera (POIs) con HTTP 200; la cabecera la delata.
  if (!col.containsKey('radius_m')) {
    throw const FormatException('la cabecera no tiene radius_m '
        '(¿existe la pestaña?)');
  }
  return [
    for (final row in rows.skip(1))
      if (_cell(row, col, 'id').isNotEmpty &&
          double.tryParse(_cell(row, col, 'lat')) != null &&
          double.tryParse(_cell(row, col, 'lon')) != null)
        Watchtower(
          id: _cell(row, col, 'id'),
          name: _cell(row, col, 'name'),
          location: LatLng(double.parse(_cell(row, col, 'lat')),
              double.parse(_cell(row, col, 'lon'))),
          revealRadiusMeters: double.tryParse(_cell(row, col, 'radius_m')) ??
              kWatchtowerRevealRadiusMeters,
        ),
  ];
}

List<List<String>> _rows(String csv) => Csv(dynamicTyping: false)
    .decode(csv)
    .map((r) => r.map((c) => c.toString()).toList())
    .where((r) => r.any((c) => c.trim().isNotEmpty))
    .toList();

Map<String, int> _header(List<String> headerRow) => {
      for (var i = 0; i < headerRow.length; i++)
        headerRow[i].trim().toLowerCase(): i,
    };

String _cell(List<String> row, Map<String, int> col, String name) {
  final i = col[name];
  return (i == null || i >= row.length) ? '' : row[i].trim();
}
