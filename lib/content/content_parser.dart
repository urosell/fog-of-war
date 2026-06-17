// Convierte el CSV de la hoja (dos pestañas) en objetos del juego.
//
// Es tolerante a fallos a propósito: una fila mal formada se ignora (con aviso
// en depuración) en vez de tumbar toda la carga. Así un error tuyo en una celda
// no deja a los usuarios sin contenido.

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:latlong2/latlong.dart';

import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import 'content_config.dart';
import 'game_content.dart';
import 'icon_catalog.dart';

/// Parsea las dos pestañas (CSV en texto) a un [GameContent]. Lanza si AMBAS
/// listas quedan vacías (señal de CSV inválido: el llamador conserva lo previo).
GameContent parseContent(String poisCsv, String collectionsCsv) {
  final pois = _parsePois(poisCsv);
  final collections = _parseCollections(collectionsCsv);
  if (pois.isEmpty && collections.isEmpty) {
    throw const FormatException('Contenido vacío tras parsear el CSV');
  }
  return GameContent(pois: pois, collections: collections);
}

// --- POIs -----------------------------------------------------------------

List<Poi> _parsePois(String csv) {
  final rows = _toRows(csv);
  if (rows.isEmpty) return const [];
  final col = _header(rows.first);
  final out = <Poi>[];
  final seen = <String>{};
  for (final row in rows.skip(1)) {
    final id = _cell(row, col, 'id');
    final lat = double.tryParse(_cell(row, col, 'lat'));
    final lon = double.tryParse(_cell(row, col, 'lon'));
    if (id.isEmpty || lat == null || lon == null) {
      _warn('POI ignorado (id/lat/lon inválidos): $row');
      continue;
    }
    if (!seen.add(id)) {
      _warn('POI con id duplicado, ignorado: $id');
      continue;
    }
    final mapsUrl = _cell(row, col, 'maps_url');
    out.add(Poi(
      id: id,
      name: _cell(row, col, 'name'),
      location: LatLng(lat, lon),
      category: _category(_cell(row, col, 'category')),
      customMapsUrl: mapsUrl.isEmpty ? null : mapsUrl,
    ));
  }
  return out;
}

PoiCategory _category(String raw) {
  final name = raw.trim().toLowerCase();
  for (final c in PoiCategory.values) {
    if (c.name == name) return c;
  }
  _warn('Categoría desconocida "$raw", usando "plaza"');
  return PoiCategory.plaza;
}

// --- Colecciones ----------------------------------------------------------

List<PoiCollection> _parseCollections(String csv) {
  final rows = _toRows(csv);
  if (rows.isEmpty) return const [];
  final col = _header(rows.first);
  final out = <PoiCollection>[];
  final seen = <String>{};
  for (final row in rows.skip(1)) {
    final id = _cell(row, col, 'id');
    if (id.isEmpty) {
      _warn('Colección ignorada (sin id): $row');
      continue;
    }
    if (!seen.add(id)) {
      _warn('Colección con id duplicado, ignorada: $id');
      continue;
    }

    final names = <String, String>{};
    final descriptions = <String, String>{};
    for (final loc in kContentLocales) {
      final n = _cell(row, col, 'name_$loc');
      final d = _cell(row, col, 'desc_$loc');
      if (n.isNotEmpty) names[loc] = n;
      if (d.isNotEmpty) descriptions[loc] = d;
    }
    // Texto base = español, o el primero que haya, o el id.
    final baseName = names['es'] ??
        (names.isNotEmpty ? names.values.first : id);
    final baseDesc = descriptions['es'] ??
        (descriptions.isNotEmpty ? descriptions.values.first : '');

    final poiIds = _cell(row, col, 'poi_ids')
        .split(RegExp(r'[;,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    out.add(PoiCollection(
      id: id,
      name: baseName,
      description: baseDesc,
      icon: iconFromName(_cell(row, col, 'icon')),
      accent: _color(_cell(row, col, 'color')),
      poiIds: poiIds,
      names: names,
      descriptions: descriptions,
    ));
  }
  return out;
}

/// Color desde hex ("#RRGGBB", "RRGGBB" o "0xFFRRGGBB"). Gris si es inválido.
Color _color(String raw) {
  var hex = raw.trim().replaceAll('#', '').replaceAll('0x', '');
  if (hex.length == 6) hex = 'FF$hex'; // añade alfa opaco
  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    _warn('Color inválido "$raw", usando gris');
    return const Color(0xFF9E9E9E);
  }
  return Color(value);
}

// --- Utilidades CSV -------------------------------------------------------

List<List<String>> _toRows(String csv) {
  if (csv.trim().isEmpty) return const [];
  // dynamicTyping: false → todo como texto (parseamos lat/lon nosotros).
  final raw = Csv(dynamicTyping: false).decode(csv);
  return raw
      .map((r) => r.map((c) => c.toString()).toList())
      .where((r) => r.any((c) => c.trim().isNotEmpty)) // descarta filas vacías
      .toList();
}

/// Mapa nombre-de-columna → índice (cabecera en minúsculas y sin espacios).
Map<String, int> _header(List<String> headerRow) {
  final map = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    map[headerRow[i].trim().toLowerCase()] = i;
  }
  return map;
}

String _cell(List<String> row, Map<String, int> col, String name) {
  final i = col[name];
  if (i == null || i >= row.length) return '';
  return row[i].trim();
}

void _warn(String msg) {
  if (kDebugMode) debugPrint('[content] $msg');
}
