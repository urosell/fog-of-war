// Tests del FogController, centrados en el contador incremental de celdas por
// ciudad (discoveredCountInCity): debe coincidir siempre con el recuento
// "lento" de City.discoveredCount sobre el conjunto completo.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fog_of_war/cities/city.dart';
import 'package:fog_of_war/fog/fog_controller.dart';
import 'package:fog_of_war/fog/fog_storage.dart';
import 'package:fog_of_war/fog/tile_math.dart';

/// Almacenamiento en memoria para no tocar el disco (ni path_provider).
class _MemoryFogStorage extends FogStorage {
  Set<CellId> data = <CellId>{};

  @override
  Future<Set<CellId>> load() async => Set<CellId>.of(data);

  @override
  Future<void> save(Set<CellId> cells) async => data = Set<CellId>.of(cells);
}

// Posiciones de control: dentro de Barcelona y dentro de Madrid.
const _enBarcelona = LatLng(41.3874, 2.1686);
const _enMadrid = LatLng(40.4168, -3.7038);

void main() {
  group('FogController.discoveredCountInCity', () {
    FogController build() => FogController(storage: _MemoryFogStorage());

    test('empieza a cero para todas las ciudades', () {
      final c = build();
      for (final city in kCities) {
        expect(c.discoveredCountInCity(city.id), 0);
      }
      c.dispose();
    });

    test('revelar en Barcelona cuenta en Barcelona y no en Madrid, y cuadra '
        'con el recuento lento sobre el conjunto completo', () {
      final c = build();
      c.reveal(_enBarcelona);
      expect(c.discoveredCountInCity(kBarcelona.id), greaterThan(0));
      expect(c.discoveredCountInCity(kBarcelona.id),
          kBarcelona.discoveredCount(c.discovered));
      expect(c.discoveredCountInCity('madrid_es'), 0);
      c.dispose();
    });

    test('acumula entre ciudades sin mezclarlas', () {
      final c = build();
      c.reveal(_enBarcelona);
      c.reveal(_enMadrid);
      for (final city in kCities) {
        expect(c.discoveredCountInCity(city.id),
            city.discoveredCount(c.discovered),
            reason: 'contador de ${city.id}');
      }
      c.dispose();
    });

    test('load() reconstruye los contadores desde lo guardado', () async {
      final storage = _MemoryFogStorage()
        ..data = cellsWithinRadius(_enBarcelona, 50);
      final c = FogController(storage: storage);
      await c.load();
      expect(c.discoveredCountInCity(kBarcelona.id),
          kBarcelona.discoveredCount(c.discovered));
      expect(c.discoveredCountInCity(kBarcelona.id), greaterThan(0));
      c.dispose();
    });

    test('clear() pone los contadores a cero', () {
      final c = build();
      c.reveal(_enBarcelona);
      c.clear();
      expect(c.discoveredCountInCity(kBarcelona.id), 0);
      expect(c.discoveredCount, 0);
      c.dispose();
    });

    test('ciudad desconocida devuelve 0', () {
      final c = build();
      c.reveal(_enBarcelona);
      expect(c.discoveredCountInCity('atlantis'), 0);
      c.dispose();
    });
  });
}
