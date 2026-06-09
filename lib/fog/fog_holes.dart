// Relleno de "agujeros" pequeños de niebla.
//
// Un agujero es un grupo de celdas SIN descubrir totalmente rodeado de celdas
// descubiertas (no tiene salida hacia la niebla exterior). Esto pasa, sobre
// todo, por imprecisión del GPS: pasas por una zona pero queda una celda suelta
// sin marcar en medio. Si el agujero es pequeño, lo rellenamos para que el mapa
// (y el contador) reflejen que esa zona ya está explorada.
//
// El algoritmo es un "flood fill" (relleno por inundación) acotado a una caja:
// recorre las celdas no descubiertas, agrupa las que están conectadas, y si un
// grupo NO toca el borde de la caja (está encerrado) y es pequeño, lo rellena.

import 'tile_math.dart';

/// Busca agujeros cerrados de niebla dentro de la caja [minX..maxX, minY..maxY]
/// y devuelve las celdas a rellenar: las de grupos encerrados de tamaño menor o
/// igual a [maxHoleCells]. Los grupos que tocan el borde de la caja se
/// consideran "abiertos" (conectados a la niebla de fuera) y NO se rellenan.
Set<CellId> findEnclosedHoles(
  Set<CellId> discovered, {
  required int minX,
  required int minY,
  required int maxX,
  required int maxY,
  required int maxHoleCells,
}) {
  final fill = <CellId>{};
  final visited = <CellId>{};

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final start = CellId(x, y);
      if (discovered.contains(start) || visited.contains(start)) continue;

      // Recorrer todo el grupo de celdas no descubiertas conectado a 'start'.
      final component = <CellId>[];
      final queue = <CellId>[start];
      visited.add(start);
      var touchesBorder = false;

      while (queue.isNotEmpty) {
        final c = queue.removeLast();
        component.add(c);
        if (c.x == minX || c.x == maxX || c.y == minY || c.y == maxY) {
          touchesBorder = true;
        }
        for (final n in _neighbors4(c)) {
          if (n.x < minX || n.x > maxX || n.y < minY || n.y > maxY) continue;
          if (discovered.contains(n) || visited.contains(n)) continue;
          visited.add(n);
          queue.add(n);
        }
      }

      // Encerrado (no toca el borde) y pequeño: es un agujero que rellenamos.
      if (!touchesBorder && component.length <= maxHoleCells) {
        fill.addAll(component);
      }
    }
  }

  return fill;
}

// Las 4 celdas vecinas (arriba, abajo, izquierda, derecha). Usamos conectividad
// de 4 (no diagonal) para no "saltar" por esquinas.
List<CellId> _neighbors4(CellId c) => [
      CellId(c.x + 1, c.y),
      CellId(c.x - 1, c.y),
      CellId(c.x, c.y + 1),
      CellId(c.x, c.y - 1),
    ];
