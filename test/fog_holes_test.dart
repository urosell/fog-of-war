import 'package:flutter_test/flutter_test.dart';

import 'package:fog_of_war/fog/fog_holes.dart';
import 'package:fog_of_war/fog/tile_math.dart';

// Construye un bloque relleno de celdas descubiertas [x0..x1, y0..y1].
Set<CellId> _bloque(int x0, int y0, int x1, int y1) {
  final s = <CellId>{};
  for (var x = x0; x <= x1; x++) {
    for (var y = y0; y <= y1; y++) {
      s.add(CellId(x, y));
    }
  }
  return s;
}

void main() {
  group('findEnclosedHoles', () {
    test('una celda suelta rodeada se detecta como agujero', () {
      // Bloque 3x3 lleno, pero quitamos el centro (10,10).
      final discovered = _bloque(9, 9, 11, 11)..remove(const CellId(10, 10));
      final huecos = findEnclosedHoles(
        discovered,
        minX: 8, minY: 8, maxX: 12, maxY: 12,
        maxHoleCells: 4,
      );
      expect(huecos, {const CellId(10, 10)});
    });

    test('sin agujeros, no rellena nada', () {
      final discovered = _bloque(9, 9, 11, 11);
      final huecos = findEnclosedHoles(
        discovered,
        minX: 8, minY: 8, maxX: 12, maxY: 12,
        maxHoleCells: 4,
      );
      expect(huecos, isEmpty);
    });

    test('un hueco abierto (que toca el borde / con salida) no se rellena', () {
      // Marco en forma de "C": rodeado salvo por la derecha, así el hueco
      // conecta con el exterior y NO debe rellenarse.
      final discovered = _bloque(9, 9, 11, 11)
        ..remove(const CellId(10, 10))
        ..remove(const CellId(11, 10)); // abre la pared derecha
      final huecos = findEnclosedHoles(
        discovered,
        minX: 8, minY: 8, maxX: 12, maxY: 12,
        maxHoleCells: 4,
      );
      expect(huecos, isEmpty);
    });

    test('un agujero más grande que el máximo no se rellena', () {
      // Bloque 6x6 lleno con un hueco interior de 2x2 (4 celdas). Con
      // maxHoleCells=3, ese agujero es demasiado grande.
      final discovered = _bloque(0, 0, 5, 5)
        ..remove(const CellId(2, 2))
        ..remove(const CellId(3, 2))
        ..remove(const CellId(2, 3))
        ..remove(const CellId(3, 3));
      final huecos = findEnclosedHoles(
        discovered,
        minX: 0, minY: 0, maxX: 5, maxY: 5,
        maxHoleCells: 3,
      );
      expect(huecos, isEmpty);
    });

    test('ese mismo agujero de 4 celdas sí se rellena si cabe en el máximo', () {
      final discovered = _bloque(0, 0, 5, 5)
        ..remove(const CellId(2, 2))
        ..remove(const CellId(3, 2))
        ..remove(const CellId(2, 3))
        ..remove(const CellId(3, 3));
      final huecos = findEnclosedHoles(
        discovered,
        minX: 0, minY: 0, maxX: 5, maxY: 5,
        maxHoleCells: 4,
      );
      expect(huecos, {
        const CellId(2, 2),
        const CellId(3, 2),
        const CellId(2, 3),
        const CellId(3, 3),
      });
    });
  });
}
