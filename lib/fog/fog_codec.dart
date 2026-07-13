// Codec del fog: convierte el conjunto de celdas descubiertas a bytes y al revés.
//
// Formato compacto (el que recomienda el blueprint): las celdas se agrupan por
// tiles Z16; cada tile guarda un bitmap de 256 bits (32 bytes), donde cada bit
// indica si una celda está descubierta (1) o no (0).
//
// Estructura del archivo (todo big-endian):
//   [1 byte ] versión del formato
//   [4 bytes] número de tiles (uint32)
//   por cada tile:
//     [4 bytes] x del tile (int32)
//     [4 bytes] y del tile (int32)
//     [32 bytes] bitmap de las 256 celdas
//
// El byte de versión permite migrar el formato en el futuro sin romper datos
// antiguos (riesgo crítico señalado en el blueprint).

import 'dart:typed_data';

import 'tile_math.dart';

/// Versión actual del formato de serialización del fog.
const int kFogFormatVersion = 1;

/// Bytes que ocupa el bitmap de un tile (256 celdas / 8 bits = 32 bytes).
const int kTileBitmapBytes = 32;

/// Bitmap de 32 bytes de UN tile a partir de sus celdas descubiertas.
/// Es el mismo formato por-tile del archivo local, y también lo que sube el
/// sync a la tabla `fog_tiles` (una fila por tile; ver lib/cloud/).
Uint8List encodeTileBitmap(Iterable<CellId> cellsOfTile) {
  final bitmap = Uint8List(kTileBitmapBytes);
  for (final cell in cellsOfTile) {
    final bit = bitIndexForCell(cell);
    bitmap[bit >> 3] |= (1 << (bit & 7));
  }
  return bitmap;
}

/// Celdas de UN tile a partir de su bitmap de 32 bytes (inversa de
/// [encodeTileBitmap]). Un bitmap corto/corrupto devuelve solo lo legible.
Set<CellId> decodeTileBitmap(TileId tile, Uint8List bitmap) {
  final result = <CellId>{};
  final len =
      bitmap.length < kTileBitmapBytes ? bitmap.length : kTileBitmapBytes;
  for (var byteIdx = 0; byteIdx < len; byteIdx++) {
    final b = bitmap[byteIdx];
    if (b == 0) continue;
    for (var bit = 0; bit < 8; bit++) {
      if ((b & (1 << bit)) != 0) {
        result.add(cellFromTileAndBit(tile, (byteIdx << 3) + bit));
      }
    }
  }
  return result;
}

/// Serializa las celdas descubiertas a bytes.
Uint8List encodeFog(Set<CellId> cells) {
  // Agrupar celdas por tile Z16, construyendo el bitmap de cada uno.
  final tiles = <TileId, Uint8List>{};
  for (final cell in cells) {
    final tile = tileForCell(cell);
    final bitmap = tiles.putIfAbsent(tile, () => Uint8List(kTileBitmapBytes));
    final bit = bitIndexForCell(cell);
    bitmap[bit >> 3] |= (1 << (bit & 7));
  }

  final totalBytes = 1 + 4 + tiles.length * (4 + 4 + kTileBitmapBytes);
  final out = Uint8List(totalBytes);
  final view = ByteData.view(out.buffer);

  var offset = 0;
  view.setUint8(offset, kFogFormatVersion);
  offset += 1;
  view.setUint32(offset, tiles.length);
  offset += 4;

  tiles.forEach((tile, bitmap) {
    view.setInt32(offset, tile.x);
    offset += 4;
    view.setInt32(offset, tile.y);
    offset += 4;
    out.setRange(offset, offset + kTileBitmapBytes, bitmap);
    offset += kTileBitmapBytes;
  });

  return out;
}

/// Reconstruye el conjunto de celdas descubiertas a partir de los bytes.
/// Devuelve un conjunto vacío si los datos están vacíos o son ilegibles.
Set<CellId> decodeFog(Uint8List bytes) {
  final result = <CellId>{};
  if (bytes.lengthInBytes < 5) return result; // sin cabecera mínima

  final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  var offset = 0;

  final version = view.getUint8(offset);
  offset += 1;
  if (version != kFogFormatVersion) {
    // En el futuro: aquí iría la migración de versiones antiguas.
    return result;
  }

  final tileCount = view.getUint32(offset);
  offset += 4;

  for (var t = 0; t < tileCount; t++) {
    // Comprobación defensiva por si el archivo está truncado.
    if (offset + 8 + kTileBitmapBytes > bytes.lengthInBytes) break;

    final tx = view.getInt32(offset);
    offset += 4;
    final ty = view.getInt32(offset);
    offset += 4;
    final tile = TileId(tx, ty);

    for (var byteIdx = 0; byteIdx < kTileBitmapBytes; byteIdx++) {
      final b = view.getUint8(offset + byteIdx);
      if (b == 0) continue;
      for (var bit = 0; bit < 8; bit++) {
        if ((b & (1 << bit)) != 0) {
          result.add(cellFromTileAndBit(tile, (byteIdx << 3) + bit));
        }
      }
    }
    offset += kTileBitmapBytes;
  }

  return result;
}
