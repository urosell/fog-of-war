import 'package:flutter_test/flutter_test.dart';
import 'package:fog_of_war/cloud/cloud_auth.dart';

void main() {
  group('normalizeDisplayName', () {
    test('recorta espacios de los bordes y colapsa los internos', () {
      expect(normalizeDisplayName('  Uros   el  Explorador '),
          'Uros el Explorador');
    });

    test('deja un nombre normal tal cual', () {
      expect(normalizeDisplayName('NieblaKiller'), 'NieblaKiller');
    });

    test('vacío o solo espacios: null (no hay nada que guardar)', () {
      expect(normalizeDisplayName(''), isNull);
      expect(normalizeDisplayName('   '), isNull);
      expect(normalizeDisplayName('\t\n'), isNull);
    });

    test('más largo que el máximo: null', () {
      expect(normalizeDisplayName('x' * (kDisplayNameMaxLength + 1)), isNull);
      expect(normalizeDisplayName('x' * kDisplayNameMaxLength), isNotNull);
    });

    test('el colapso de espacios puede salvar un nombre al borde del límite',
        () {
      // 30 letras + 15 espacios internos = 45 crudos, 31 tras colapsar.
      final raw = '${'x' * 30}${' ' * 15}y';
      expect(normalizeDisplayName(raw), '${'x' * 30} y');
    });
  });
}
