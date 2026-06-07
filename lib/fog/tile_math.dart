// Matemáticas del grid del fog of war.
//
// Idea clave: una "celda" (la unidad mínima que se desvela) es un tile estándar
// de mapa en el nivel de zoom 20. A ese zoom cada celda mide ~38 m de lado en el
// ecuador, que es la resolución que pide el blueprint.
//
// Usamos el sistema "slippy map" (el mismo de OpenStreetMap) para convertir
// coordenadas geográficas (lat/lng) a coordenadas de celda (x, y) enteras.

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Nivel de zoom que define el tamaño de una celda.
/// Z20 ≈ 38 m por celda en el ecuador.
const int kCellZoom = 20;

/// Nivel de zoom del "tile" de almacenamiento. Un tile Z16 contiene 16x16 = 256
/// celdas Z20 (porque 16 = 2^4 y 20 - 16 = 4). Cada tile se guarda como un
/// bitmap de 256 bits = 32 bytes (ver fog_codec.dart).
const int kStorageTileZoom = 16;

/// Número de celdas por lado dentro de un tile de almacenamiento: 2^4 = 16.
const int kCellsPerTileSide = 1 << (kCellZoom - kStorageTileZoom); // 16

/// Identificador del tile de almacenamiento Z16 que contiene una celda.
class TileId {
  final int x;
  final int y;

  const TileId(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is TileId && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'TileId($x, $y)';
}

/// Tile de almacenamiento al que pertenece una celda (división entera por 16).
TileId tileForCell(CellId cell) =>
    TileId(cell.x ~/ kCellsPerTileSide, cell.y ~/ kCellsPerTileSide);

/// Índice de bit (0..255) de una celda dentro de su tile.
/// Fila (y local) * 16 + columna (x local).
int bitIndexForCell(CellId cell) {
  final localX = cell.x % kCellsPerTileSide;
  final localY = cell.y % kCellsPerTileSide;
  return localY * kCellsPerTileSide + localX;
}

/// Reconstruye una celda a partir de su tile y su índice de bit.
CellId cellFromTileAndBit(TileId tile, int bitIndex) {
  final localY = bitIndex ~/ kCellsPerTileSide;
  final localX = bitIndex % kCellsPerTileSide;
  return CellId(
    tile.x * kCellsPerTileSide + localX,
    tile.y * kCellsPerTileSide + localY,
  );
}

/// Identificador de una celda del grid: coordenadas enteras (x, y) en el zoom
/// [kCellZoom]. Dos celdas son iguales si tienen el mismo x e y.
class CellId {
  final int x;
  final int y;

  const CellId(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is CellId && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'CellId($x, $y)';
}

/// Número de celdas por lado del mundo en el zoom [kCellZoom]: 2^zoom.
double _worldSizeInCells(int zoom) => math.pow(2, zoom).toDouble();

/// Convierte una latitud/longitud a la celda que la contiene.
CellId cellForLatLng(LatLng position, {int zoom = kCellZoom}) {
  final n = _worldSizeInCells(zoom);
  final latRad = position.latitude * math.pi / 180.0;

  final x = ((position.longitude + 180.0) / 360.0 * n).floor();
  final y = ((1.0 - _asinh(math.tan(latRad)) / math.pi) / 2.0 * n).floor();

  // Aseguramos que x,y queden dentro del rango válido [0, n-1].
  final maxIndex = n.toInt() - 1;
  return CellId(x.clamp(0, maxIndex), y.clamp(0, maxIndex));
}

/// Devuelve la esquina noroeste (arriba-izquierda) de una celda en lat/lng.
/// La esquina sureste de la celda es la noroeste de la celda (x+1, y+1).
LatLng cellNorthWest(CellId cell, {int zoom = kCellZoom}) {
  final n = _worldSizeInCells(zoom);
  final lng = cell.x / n * 360.0 - 180.0;
  final latRad = math.atan(_sinh(math.pi * (1.0 - 2.0 * cell.y / n)));
  final lat = latRad * 180.0 / math.pi;
  return LatLng(lat, lng);
}

/// Centro geográfico de una celda.
LatLng cellCenter(CellId cell, {int zoom = kCellZoom}) {
  final nw = cellNorthWest(cell, zoom: zoom);
  final se = cellNorthWest(CellId(cell.x + 1, cell.y + 1), zoom: zoom);
  return LatLng((nw.latitude + se.latitude) / 2, (nw.longitude + se.longitude) / 2);
}

/// Devuelve todas las celdas cuyo centro cae dentro de [radiusMeters] desde
/// [center]. Esto es lo que se "desvela" cuando el jugador pasa por un punto.
Set<CellId> cellsWithinRadius(LatLng center, double radiusMeters,
    {int zoom = kCellZoom}) {
  final centerCell = cellForLatLng(center, zoom: zoom);

  // Tamaño aproximado de una celda en metros a esta latitud.
  // En x el tamaño se encoge con el coseno de la latitud.
  final latRad = center.latitude * math.pi / 180.0;
  final n = _worldSizeInCells(zoom);
  const earthCircumference = 40075016.686; // metros, en el ecuador
  final cellMetersX = earthCircumference * math.cos(latRad) / n;
  final cellMetersY = earthCircumference / n;

  // Cuántas celdas hay que mirar en cada dirección para cubrir el radio.
  final spanX = (radiusMeters / cellMetersX).ceil() + 1;
  final spanY = (radiusMeters / cellMetersY).ceil() + 1;

  final result = <CellId>{};
  for (var dx = -spanX; dx <= spanX; dx++) {
    for (var dy = -spanY; dy <= spanY; dy++) {
      final candidate = CellId(centerCell.x + dx, centerCell.y + dy);
      final distance = _distanceMeters(center, cellCenter(candidate, zoom: zoom));
      if (distance <= radiusMeters) {
        result.add(candidate);
      }
    }
  }
  // El centro siempre cuenta como descubierto, aunque el radio sea muy pequeño.
  result.add(centerCell);
  return result;
}

/// Distancia aproximada en metros entre dos puntos cercanos
/// (aproximación equirectangular, suficiente a escala de decenas de metros).
double _distanceMeters(LatLng a, LatLng b) {
  final meanLatRad = (a.latitude + b.latitude) / 2 * math.pi / 180.0;
  final dx = (b.longitude - a.longitude) * math.cos(meanLatRad) * 111320.0;
  final dy = (b.latitude - a.latitude) * 110540.0;
  return math.sqrt(dx * dx + dy * dy);
}

// Funciones hiperbólicas que dart:math no trae directamente.
double _asinh(double x) => math.log(x + math.sqrt(x * x + 1));
double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
