// Tests del codec del fog (serialización a bytes y vuelta).

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_of_war/fog/fog_codec.dart';
import 'package:fog_of_war/fog/tile_math.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('encode/decode', () {
    test('conjunto vacío se serializa y recupera como vacío', () {
      final bytes = encodeFog({});
      expect(decodeFog(bytes), isEmpty);
    });

    test('ida y vuelta conserva exactamente las celdas', () {
      final original = {
        const CellId(0, 0),
        const CellId(1, 0),
        const CellId(15, 15), // misma esquina de un tile
        const CellId(16, 16), // primera celda del tile siguiente
        const CellId(1000, 2000),
      };
      final recuperado = decodeFog(encodeFog(original));
      expect(recuperado, equals(original));
    });

    test('celdas reales de un radio sobreviven a la serialización', () {
      final cells = cellsWithinRadius(const LatLng(41.3874, 2.1686), 50.0);
      final recuperado = decodeFog(encodeFog(cells));
      expect(recuperado, equals(cells));
    });

    test('es compacto: 256 celdas de un tile caben en ~41 bytes', () {
      // Rellenar un tile entero (16x16 = 256 celdas).
      final cells = <CellId>{};
      for (var x = 0; x < 16; x++) {
        for (var y = 0; y < 16; y++) {
          cells.add(CellId(x, y));
        }
      }
      final bytes = encodeFog(cells);
      // 1 (versión) + 4 (count) + 4 + 4 (x,y) + 32 (bitmap) = 45 bytes.
      expect(bytes.lengthInBytes, equals(45));
    });

    test('datos corruptos/cortos devuelven vacío sin lanzar excepción', () {
      expect(decodeFog(Uint8List(0)), isEmpty);
      expect(decodeFog(Uint8List.fromList([0, 0, 0])), isEmpty);
    });

    test('versión desconocida devuelve vacío (no rompe)', () {
      final bytes = encodeFog({const CellId(5, 5)});
      bytes[0] = 99; // falsear la versión
      expect(decodeFog(bytes), isEmpty);
    });
  });

  group('bitmap por tile (formato del sync en la nube)', () {
    test('ida y vuelta conserva las celdas de un tile', () {
      // Celdas variadas del mismo tile (bits 0, 7, 128 y 255).
      const tile = TileId(32000, 24000);
      final cells = {
        cellFromTileAndBit(tile, 0),
        cellFromTileAndBit(tile, 7),
        cellFromTileAndBit(tile, 128),
        cellFromTileAndBit(tile, 255),
      };
      final bitmap = encodeTileBitmap(cells);
      expect(bitmap.length, kTileBitmapBytes);
      expect(decodeTileBitmap(tile, bitmap), cells);
    });

    test('bitmap vacío = sin celdas; corto/corrupto no lanza', () {
      const tile = TileId(1, 1);
      expect(decodeTileBitmap(tile, Uint8List(kTileBitmapBytes)), isEmpty);
      expect(decodeTileBitmap(tile, Uint8List(3)), isEmpty);
    });
  });
}
