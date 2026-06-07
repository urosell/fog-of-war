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
}
