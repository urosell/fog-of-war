import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fog_of_war/cities/city.dart';
import 'package:fog_of_war/fog/tile_math.dart';

void main() {
  group('City', () {
    test('totalCells es positivo y coherente con el tamaño de la caja', () {
      // La caja de Barcelona es de varios km: debe contener muchas celdas.
      expect(kBarcelona.totalCells, greaterThan(10000));
    });

    test('una celda en el centro de la ciudad está dentro', () {
      final centro = cellForLatLng(const LatLng(41.3874, 2.1686));
      expect(kBarcelona.containsCell(centro), isTrue);
    });

    test('una celda lejos de la ciudad está fuera', () {
      final lejos = cellForLatLng(const LatLng(40.4168, -3.7038)); // Madrid
      expect(kBarcelona.containsCell(lejos), isFalse);
    });

    test('discoveredCount solo cuenta las celdas dentro de la ciudad', () {
      final dentro = cellForLatLng(const LatLng(41.3874, 2.1686));
      final fuera = cellForLatLng(const LatLng(40.4168, -3.7038));
      final discovered = {dentro, fuera};
      expect(kBarcelona.discoveredCount(discovered), 1);
    });

    test('discoveryPercentage es 0 sin celdas y >0 con una celda dentro', () {
      expect(kBarcelona.discoveryPercentage({}), 0);

      final dentro = cellForLatLng(const LatLng(41.3874, 2.1686));
      final pct = kBarcelona.discoveryPercentage({dentro});
      expect(pct, greaterThan(0));
      expect(pct, lessThan(1)); // una sola celda es una fracción minúscula
    });

    test('desvelar toda la caja da 100%', () {
      // Construimos el conjunto completo de celdas de una ciudad pequeña
      // (caja diminuta) y comprobamos que el porcentaje es 100.
      const mini = City(
        id: 'mini',
        name: 'Mini',
        south: 41.3870,
        west: 2.1680,
        north: 41.3878,
        east: 2.1692,
      );
      final swCell = cellForLatLng(const LatLng(41.3870, 2.1692)); // sur-este
      final nwCell = cellForLatLng(const LatLng(41.3878, 2.1680)); // norte-oeste
      final todas = <CellId>{};
      for (var x = nwCell.x; x <= swCell.x; x++) {
        for (var y = nwCell.y; y <= swCell.y; y++) {
          todas.add(CellId(x, y));
        }
      }
      expect(mini.discoveryPercentage(todas), closeTo(100, 0.0001));
    });
  });
}
