// Tests de la matemática del grid del fog.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fog_of_war/fog/tile_math.dart';

void main() {
  group('cellForLatLng', () {
    test('es estable: la misma coordenada da siempre la misma celda', () {
      const barcelona = LatLng(41.3874, 2.1686);
      final a = cellForLatLng(barcelona);
      final b = cellForLatLng(barcelona);
      expect(a, equals(b));
    });

    test('coordenadas distintas y lejanas dan celdas distintas', () {
      final bcn = cellForLatLng(const LatLng(41.3874, 2.1686));
      final mad = cellForLatLng(const LatLng(40.4168, -3.7038));
      expect(bcn, isNot(equals(mad)));
    });

    test('moverse al este aumenta x; moverse al norte disminuye y', () {
      const base = LatLng(41.3874, 2.1686);
      final baseCell = cellForLatLng(base);
      // ~0.01 grados de longitud al este, latitud arriba.
      final eastCell = cellForLatLng(const LatLng(41.3874, 2.1786));
      final northCell = cellForLatLng(const LatLng(41.3974, 2.1686));
      expect(eastCell.x, greaterThan(baseCell.x));
      expect(northCell.y, lessThan(baseCell.y));
    });
  });

  group('conversión ida y vuelta', () {
    test('lat/lng -> celda -> centro queda dentro de la misma celda', () {
      const p = LatLng(41.3874, 2.1686);
      final cell = cellForLatLng(p);
      final center = cellCenter(cell);
      // El centro de la celda debe mapear a la misma celda.
      expect(cellForLatLng(center), equals(cell));
    });
  });

  group('cellsWithinRadius', () {
    test('un radio pequeño desvela al menos la celda central', () {
      const p = LatLng(41.3874, 2.1686);
      final cells = cellsWithinRadius(p, 1.0);
      expect(cells, contains(cellForLatLng(p)));
      expect(cells.length, greaterThanOrEqualTo(1));
    });

    test('un radio mayor desvela más celdas que uno menor', () {
      const p = LatLng(41.3874, 2.1686);
      final small = cellsWithinRadius(p, 20.0);
      final big = cellsWithinRadius(p, 100.0);
      expect(big.length, greaterThan(small.length));
    });

    test('radio de 50 m desvela un puñado de celdas (~38 m cada una)', () {
      const p = LatLng(41.3874, 2.1686);
      final cells = cellsWithinRadius(p, 50.0);
      // A ~38 m/celda, 50 m de radio cubre un área de pocas celdas.
      expect(cells.length, inInclusiveRange(5, 40));
    });
  });
}
