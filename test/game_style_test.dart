// Tests del builder del theme de las skins (game_style.dart): estructura de
// capas, interruptores de experimento (GameThemeTweaks) y que el JSON parsea
// con el ThemeReader real de vector_tile_renderer. Todo sin red: se prueba el
// JSON generado, no la descarga del estilo base.

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_of_war/map/game_style.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

List<String> _ids(Map<String, dynamic> json) =>
    (json['layers'] as List).map((l) => l['id'] as String).toList();

void main() {
  group('theme clásico (Juego)', () {
    test('lleva todas las capas: dilate y etiquetas incluidas', () {
      final ids = _ids(classicThemeJsonForTest());
      expect(ids, contains('building'));
      expect(ids, contains('building_dilate'));
      expect(ids, contains('road_label'));
      expect(ids, contains('place_label'));
    });

    test('los ids de capa son únicos', () {
      final ids = _ids(classicThemeJsonForTest());
      expect(ids.toSet().length, ids.length);
    });

    test('buildingDilate:false quita solo esa capa', () {
      final base = _ids(classicThemeJsonForTest());
      final sin = _ids(
          classicThemeJsonForTest(const GameThemeTweaks(buildingDilate: false)));
      expect(sin, isNot(contains('building_dilate')));
      expect(sin, base.where((id) => id != 'building_dilate').toList());
    });

    test('labels:false quita las dos capas de texto y nada más', () {
      final base = _ids(classicThemeJsonForTest());
      final sin = _ids(classicThemeJsonForTest(const GameThemeTweaks(labels: false)));
      expect(sin, isNot(contains('road_label')));
      expect(sin, isNot(contains('place_label')));
      expect(
          sin,
          base
              .where((id) => id != 'road_label' && id != 'place_label')
              .toList());
    });

    test('liteRoadLabels: solo vías mayores y desde z15', () {
      final json = classicThemeJsonForTest(
          const GameThemeTweaks(liteRoadLabels: true));
      final roadLabel = (json['layers'] as List)
          .firstWhere((l) => l['id'] == 'road_label') as Map<String, dynamic>;
      expect(roadLabel['minzoom'], 15);
      expect('${roadLabel['filter']}', contains('primary'));
      expect('${roadLabel['filter']}', isNot(contains('minor')));
      // La variante normal no lleva filtro y arranca en z14.
      final normal = (classicThemeJsonForTest()['layers'] as List)
          .firstWhere((l) => l['id'] == 'road_label') as Map<String, dynamic>;
      expect(normal['minzoom'], 14);
      expect(normal.containsKey('filter'), isFalse);
    });

    test('el JSON parsea con el ThemeReader real', () {
      for (final tweaks in const [
        GameThemeTweaks(),
        GameThemeTweaks(buildingDilate: false),
        GameThemeTweaks(labels: false),
        GameThemeTweaks(buildingDilate: false, labels: false),
        GameThemeTweaks(liteRoadLabels: true),
      ]) {
        final theme = vtr.ThemeReader().read(classicThemeJsonForTest(tweaks));
        expect(theme.layers, isNotEmpty);
      }
    });
  });

  group('theme corsario', () {
    test('sin etiquetas de calle (fiel a la referencia) pero con barrios', () {
      final ids = _ids(corsairThemeJsonForTest());
      expect(ids, isNot(contains('road_label')));
      expect(ids, contains('place_label'));
    });

    test('el JSON parsea con el ThemeReader real', () {
      final theme = vtr.ThemeReader().read(corsairThemeJsonForTest());
      expect(theme.layers, isNotEmpty);
    });
  });

  group('estilos de experimento', () {
    test('una skin desconocida lanza ArgumentError (y así cae al raster)', () {
      expect(() => loadExperimentStyle('exp_inventada'), throwsArgumentError);
    });
  });
}
