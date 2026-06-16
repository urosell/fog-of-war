// Tests del parser de contenido (CSV de la hoja → POIs y colecciones).
//
// Incluye un test que parsea la PLANTILLA real (docs/sheet/*.csv) para garantizar
// que el contenido de arranque que se entrega es válido y cuadra con la semilla.

import 'dart:io';

import 'package:fog_of_war/content/content_parser.dart';
import 'package:fog_of_war/poi/poi.dart';
import 'package:fog_of_war/poi/poi_collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseContent', () {
    test('parsea POIs y colecciones básicos', () {
      const pois = 'id,name,lat,lon,category\n'
          'a,Sitio A,41.4,2.1,museo\n'
          'b,Sitio B,41.5,2.2,parque\n';
      const colls =
          'id,icon,color,poi_ids,name_es,name_en,desc_es,desc_en\n'
          'c1,museum,#5C8DF6,"a;b","Mi Cole","My Coll","Desc es","Desc en"\n';

      final content = parseContent(pois, colls);

      expect(content.pois.length, 2);
      expect(content.collections.length, 1);

      final a = content.pois.firstWhere((p) => p.id == 'a');
      expect(a.name, 'Sitio A');
      expect(a.location.latitude, 41.4);
      expect(a.category, PoiCategory.museo);
      expect(a.points, PoiCategory.museo.points);

      final c = content.collections.single;
      expect(c.poiIds, ['a', 'b']);
      expect(c.localizedName('es'), 'Mi Cole');
      expect(c.localizedName('en'), 'My Coll');
      expect(c.localizedName('fr'), 'Mi Cole'); // sin fr → fallback a base (es)
      expect(c.localizedDescription('en'), 'Desc en');
    });

    test('ignora filas inválidas en vez de fallar', () {
      const pois = 'id,name,lat,lon,category\n'
          ',Sin id,41.4,2.1,museo\n' // sin id → fuera
          'b,Sin coords,,,museo\n' // sin lat/lon → fuera
          'c,Bien,41.5,2.2,parque\n';
      const colls = 'id,icon,color,poi_ids,name_es,desc_es\n'
          'ok,star,#FFB300,"c","Una","Desc"\n';

      final content = parseContent(pois, colls);
      expect(content.pois.map((p) => p.id), ['c']);
      expect(content.collections.length, 1);
    });

    test('categoría desconocida cae a plaza; color inválido no rompe', () {
      const pois = 'id,name,lat,lon,category\n'
          'x,X,41.4,2.1,inventada\n';
      const colls = 'id,icon,color,poi_ids,name_es,desc_es\n'
          'c,desconocido,nope,"x","N","D"\n';
      final content = parseContent(pois, colls);
      expect(content.pois.single.category, PoiCategory.plaza);
      expect(content.collections.single.poiIds, ['x']);
    });

    test('CSV vacío lanza (para no cachear basura)', () {
      expect(() => parseContent('', ''), throwsFormatException);
    });
  });

  group('plantilla docs/sheet', () {
    test('los CSV de arranque parsean y cuadran con la semilla', () {
      final poisCsv = File('docs/sheet/POIs.csv').readAsStringSync();
      final collsCsv = File('docs/sheet/Collections.csv').readAsStringSync();

      final content = parseContent(poisCsv, collsCsv);

      // Mismo número de POIs y colecciones que el contenido embebido.
      expect(content.pois.length, kBarcelonaPois.length);
      expect(content.collections.length, kPoiCollections.length);

      // Todos los poi_ids referenciados existen en la pestaña POIs.
      final ids = {for (final p in content.pois) p.id};
      for (final c in content.collections) {
        for (final pid in c.poiIds) {
          expect(ids.contains(pid), isTrue,
              reason: 'poi_id "$pid" de la colección "${c.id}" no existe');
        }
      }

      // Las 4 traducciones llegan (muestra: Ruta Gaudí).
      final gaudi = content.collections.firstWhere((c) => c.id == 'gaudi');
      expect(gaudi.localizedName('en'), 'Gaudí Route');
      expect(gaudi.localizedName('fr'), 'Route Gaudí');
    });
  });
}
