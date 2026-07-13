// Tests del FogController, centrados en el contador incremental de celdas por
// ciudad (discoveredCountInCity): debe coincidir siempre con el recuento
// "lento" de City.discoveredCount sobre el conjunto completo.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fog_of_war/cities/city.dart';
import 'package:fog_of_war/fog/fog_codec.dart';
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

  group('FogController: apoyo al sync en la nube', () {
    FogController build() => FogController(storage: _MemoryFogStorage());

    test('revelar marca sucios los tiles tocados y takeDirtyTiles los drena',
        () {
      final c = build();
      c.reveal(_enBarcelona);
      final sucios = c.takeDirtyTiles();
      expect(sucios, isNotEmpty);
      // Deben ser exactamente los tiles con celdas.
      expect(sucios, c.discoveredByTile.keys.toSet());
      // Drenado: una segunda llamada sin cambios no devuelve nada.
      expect(c.takeDirtyTiles(), isEmpty);
      c.dispose();
    });

    test('markTilesDirty los devuelve al pendiente (subida fallida)', () {
      final c = build();
      c.reveal(_enBarcelona);
      final sucios = c.takeDirtyTiles();
      c.markTilesDirty(sucios);
      expect(c.takeDirtyTiles(), sucios);
      c.dispose();
    });

    test('markAllTilesDirty marca todos los tiles con celdas', () {
      final c = build();
      c.reveal(_enBarcelona);
      c.reveal(_enMadrid);
      c.takeDirtyTiles(); // drenar
      c.markAllTilesDirty();
      expect(c.takeDirtyTiles(), c.discoveredByTile.keys.toSet());
      c.dispose();
    });

    test('bitmapForTile ida y vuelta reconstruye las celdas del tile', () {
      final c = build();
      c.reveal(_enBarcelona);
      for (final entry in c.discoveredByTile.entries) {
        final bitmap = c.bitmapForTile(entry.key);
        expect(decodeTileBitmap(entry.key, bitmap), entry.value.toSet());
      }
      c.dispose();
    });

    test('mergeRemoteCells une, devuelve solo las nuevas y cuadra contadores',
        () {
      final c = build();
      c.reveal(_enBarcelona);
      final locales = c.discoveredCount;

      // "Remoto": lo mismo que hay más una zona nueva (Madrid).
      final remotas = Set<CellId>.of(c.discovered)
        ..addAll(cellsWithinRadius(_enMadrid, 50));
      final nuevas = c.mergeRemoteCells(remotas);

      expect(nuevas, remotas.length - locales);
      expect(c.discoveredCount, remotas.length);
      // Los contadores por ciudad siguen cuadrando con el recuento lento.
      for (final city in kCities) {
        expect(c.discoveredCountInCity(city.id),
            city.discoveredCount(c.discovered));
      }
      // Repetir el merge no añade nada (idempotente).
      expect(c.mergeRemoteCells(remotas), 0);
      c.dispose();
    });
  });
}
