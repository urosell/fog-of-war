import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fog_of_war/poi/poi.dart';
import 'package:fog_of_war/watchtower/watchtower.dart';
import 'package:fog_of_war/watchtower/watchtower_controller.dart';
import 'package:fog_of_war/watchtower/watchtower_storage.dart';

/// Almacenamiento en memoria para no tocar el disco en los tests.
class _MemoryWatchtowerStorage extends WatchtowerStorage {
  Set<String> data;
  _MemoryWatchtowerStorage([Set<String>? initial])
      : data = initial ?? <String>{};

  @override
  Future<Set<String>> load() async => Set<String>.of(data);

  @override
  Future<void> save(Set<String> ids) async => data = Set<String>.of(ids);
}

// Una atalaya y dos POIs: uno dentro de su radio de revelado (~400 m) y otro
// muy lejos (Búnkers, varios km).
const _tower =
    Watchtower(id: 't', name: 'T', location: LatLng(41.3839, 2.1762));
const _near = Poi(
  id: 'near',
  name: 'Near',
  location: LatLng(41.3851, 2.1807),
  category: PoiCategory.museo,
);
const _far = Poi(
  id: 'far',
  name: 'Far',
  location: LatLng(41.4194, 2.1622),
  category: PoiCategory.mirador,
);

void main() {
  group('kBarcelonaWatchtowers', () {
    test('no está vacía y los IDs son únicos', () {
      expect(kBarcelonaWatchtowers, isNotEmpty);
      final ids = kBarcelonaWatchtowers.map((t) => t.id).toSet();
      expect(ids.length, kBarcelonaWatchtowers.length);
    });
  });

  group('WatchtowerController', () {
    WatchtowerController build([WatchtowerStorage? s]) => WatchtowerController(
          storage: s ?? _MemoryWatchtowerStorage(),
          towers: const [_tower],
          pois: const [_near, _far],
        );

    test('empieza sin atalayas activadas ni POIs avistados', () {
      final c = build();
      expect(c.isActivated(_tower), isFalse);
      expect(c.isSightedId('near'), isFalse);
    });

    test('activa la atalaya al acercarse y avista los POIs de su radio', () {
      final c = build();
      final nuevas = c.checkActivations(_tower.location); // justo encima
      expect(nuevas.map((t) => t.id), ['t']);
      expect(c.isActivated(_tower), isTrue);
      expect(c.isSightedId('near'), isTrue); // dentro del radio
      expect(c.isSightedId('far'), isFalse); // fuera del radio
    });

    test('no activa nada si estás lejos de toda atalaya', () {
      final c = build();
      final nuevas = c.checkActivations(const LatLng(40.4168, -3.7038)); // Madrid
      expect(nuevas, isEmpty);
      expect(c.isActivated(_tower), isFalse);
    });

    test('es idempotente: volver a pasar no reactiva', () {
      final c = build();
      c.checkActivations(_tower.location);
      final segunda = c.checkActivations(_tower.location);
      expect(segunda, isEmpty);
    });

    test('sightedCountFor cuenta los POIs dentro del radio', () {
      final c = build();
      expect(c.sightedCountFor(_tower), 1); // solo _near
    });

    test('load recalcula los avistados desde las atalayas activadas guardadas',
        () async {
      final c = build(_MemoryWatchtowerStorage({'t'}));
      await c.load();
      expect(c.isActivated(_tower), isTrue);
      expect(c.isSightedId('near'), isTrue);
      expect(c.isSightedId('far'), isFalse);
    });

    test('mergeActivated (sync nube) activa sin anuncio y recalcula avistados',
        () {
      final c = build();
      final nuevas = c.mergeActivated({'t'});
      expect(nuevas, 1);
      expect(c.isActivated(_tower), isTrue);
      expect(c.isSightedId('near'), isTrue); // avistados recalculados
      // Idempotente.
      expect(c.mergeActivated({'t'}), 0);
      expect(c.activatedIds, {'t'});
    });
  });
}
