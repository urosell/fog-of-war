import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fog_of_war/poi/poi.dart';
import 'package:fog_of_war/poi/poi_collection.dart';

// Pozo de prueba con tres POIs.
const _p1 = Poi(
  id: 'p1',
  name: 'Uno',
  location: LatLng(0, 0),
  category: PoiCategory.monumento,
);
const _p2 = Poi(
  id: 'p2',
  name: 'Dos',
  location: LatLng(0, 0),
  category: PoiCategory.museo,
);
const _p3 = Poi(
  id: 'p3',
  name: 'Tres',
  location: LatLng(0, 0),
  category: PoiCategory.tienda,
);

const _coleccion = PoiCollection(
  id: 'test',
  name: 'Test',
  description: 'desc',
  icon: Icons.star,
  accent: Color(0xFF000000),
  poiIds: ['p1', 'p3'],
);

void main() {
  final byId = {for (final p in const [_p1, _p2, _p3]) p.id: p};

  group('PoiCollection', () {
    test('resolvePois devuelve los POIs en el orden de poiIds', () {
      final pois = _coleccion.resolvePois(byId);
      expect(pois.map((p) => p.id), ['p1', 'p3']);
    });

    test('resolvePois omite IDs que no existen en el pozo', () {
      const c = PoiCollection(
        id: 'x',
        name: 'X',
        description: '',
        icon: Icons.star,
        accent: Color(0xFF000000),
        poiIds: ['p1', 'noexiste', 'p2'],
      );
      expect(c.resolvePois(byId).map((p) => p.id), ['p1', 'p2']);
    });

    test('discoveredCount cuenta solo los descubiertos de la colección', () {
      // p1 y p2 descubiertos; pero p2 no está en la colección, así que cuenta 1.
      final descubiertos = {'p1', 'p2'};
      expect(
        _coleccion.discoveredCount(descubiertos.contains),
        1,
      );
    });

    test('discoveredCount es 0 sin nada descubierto', () {
      expect(_coleccion.discoveredCount((_) => false), 0);
    });
  });

  group('Colecciones reales de Barcelona', () {
    test('todos los IDs referenciados existen en el pozo kBarcelonaPois', () {
      final pozo = {for (final p in kBarcelonaPois) p.id};
      for (final c in kPoiCollections) {
        for (final id in c.poiIds) {
          expect(pozo.contains(id), isTrue,
              reason: 'La colección "${c.id}" referencia un POI inexistente: $id');
        }
      }
    });

    test('los IDs de colección son únicos', () {
      final ids = kPoiCollections.map((c) => c.id).toSet();
      expect(ids.length, kPoiCollections.length);
    });
  });
}
