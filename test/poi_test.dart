import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fog_of_war/poi/poi.dart';
import 'package:fog_of_war/poi/poi_controller.dart';
import 'package:fog_of_war/poi/poi_storage.dart';

/// Almacenamiento en memoria para no tocar el disco en los tests.
class _MemoryPoiStorage extends PoiStorage {
  Set<String> _data = <String>{};

  @override
  Future<Set<String>> load() async => Set<String>.of(_data);

  @override
  Future<void> save(Set<String> ids) async => _data = Set<String>.of(ids);
}

// Dos POIs de prueba muy separados para controlar las distancias.
const _poiA = Poi(
  id: 'a',
  name: 'A',
  location: LatLng(41.4036, 2.1744),
  category: PoiCategory.monumento, // 50 puntos
);
const _poiB = Poi(
  id: 'b',
  name: 'B',
  location: LatLng(41.3851, 2.1807),
  category: PoiCategory.museo, // 40 puntos
);

void main() {
  group('Lista curada de Barcelona', () {
    test('no está vacía y los IDs son únicos', () {
      expect(kBarcelonaPois, isNotEmpty);
      final ids = kBarcelonaPois.map((p) => p.id).toSet();
      expect(ids.length, kBarcelonaPois.length);
    });

    test('cada POI da los puntos de su categoría', () {
      final sagrada =
          kBarcelonaPois.firstWhere((p) => p.id == 'sagrada_familia');
      expect(sagrada.points, PoiCategory.iglesia.points);
    });
  });

  group('PoiController', () {
    PoiController build() =>
        PoiController(storage: _MemoryPoiStorage(), pois: const [_poiA, _poiB]);

    test('empieza sin nada descubierto y con 0 puntos', () {
      final c = build();
      expect(c.discoveredCount, 0);
      expect(c.totalPoints, 0);
      expect(c.totalCount, 2);
    });

    test('descubre un POI al pasar dentro del radio y suma sus puntos', () {
      final c = build();
      final nuevos = c.checkDiscoveries(_poiA.location); // justo encima
      expect(nuevos.map((p) => p.id), ['a']);
      expect(c.isDiscovered(_poiA), isTrue);
      expect(c.totalPoints, 50);
      expect(c.discoveredCount, 1);
    });

    test('no descubre nada si estás lejos de todos', () {
      final c = build();
      final nuevos = c.checkDiscoveries(const LatLng(40.4168, -3.7038)); // Madrid
      expect(nuevos, isEmpty);
      expect(c.discoveredCount, 0);
    });

    test('es idempotente: volver a pasar no vuelve a descubrir ni suma doble',
        () {
      final c = build();
      c.checkDiscoveries(_poiA.location);
      final segunda = c.checkDiscoveries(_poiA.location);
      expect(segunda, isEmpty);
      expect(c.totalPoints, 50);
    });

    test('descubrir los dos suma ambos puntos', () {
      final c = build();
      c.checkDiscoveries(_poiA.location);
      c.checkDiscoveries(_poiB.location);
      expect(c.discoveredCount, 2);
      expect(c.totalPoints, 90); // 50 + 40
    });
  });
}
