// Capa visual del fog of war.
//
// Se coloca como hija de FlutterMap, encima de los tiles del mapa. Pinta un
// velo gris que cubre toda la pantalla y luego "recorta" (borra) las celdas
// que el jugador ya ha descubierto, dejando ver el mapa debajo.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'fog_controller.dart';
import 'tile_math.dart';

/// Color del velo de niebla (gris azulado, bastante opaco).
const Color kFogColor = Color(0xE6404552);

class FogLayer extends StatelessWidget {
  final FogController controller;

  /// Color del velo de niebla. Por defecto, el gris azulado del juego; cada
  /// estilo de mapa puede pasar el suyo para que pegue con el mapa de fondo.
  final Color color;

  const FogLayer({super.key, required this.controller, this.color = kFogColor});

  @override
  Widget build(BuildContext context) {
    // MapCamera.of registra esta capa como dependiente de la cámara: cuando el
    // mapa se mueve o hace zoom, este build se vuelve a ejecutar.
    final camera = MapCamera.of(context);
    return CustomPaint(
      size: camera.nonRotatedSize,
      painter: _FogPainter(camera: camera, controller: controller, color: color),
    );
  }
}

class _FogPainter extends CustomPainter {
  final MapCamera camera;
  final FogController controller;
  final Color color;

  // Pasar el controller como 'repaint' hace que el painter se redibuje cuando
  // se descubren celdas nuevas (cuando llama a notifyListeners()).
  _FogPainter({
    required this.camera,
    required this.controller,
    required this.color,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    // saveLayer aísla el dibujo para poder "borrar" con BlendMode.clear.
    canvas.saveLayer(fullRect, Paint());

    // 1) Velo cubriendo toda la pantalla (color a juego con el estilo de mapa).
    canvas.drawRect(fullRect, Paint()..color = color);

    // 2) Borrar cada celda descubierta que sea visible en pantalla.
    //
    // En vez de un cuadrado por celda (que deja bordes escalonados), abrimos un
    // CÍRCULO centrado en cada celda con un radio algo mayor que media celda:
    // así los círculos de celdas vecinas se solapan y el conjunto forma un
    // trazado redondeado y orgánico. Un ligero desenfoque suaviza el borde.
    final visible = camera.visibleBounds;

    // Tamaño en pantalla de una celda a este zoom (es constante en todo el mapa
    // para un zoom dado). Lo usamos para el radio y el desenfoque.
    final centerCell = cellForLatLng(camera.center);
    final cellNwPx = camera.latLngToScreenOffset(cellNorthWest(centerCell));
    final cellSePx = camera
        .latLngToScreenOffset(cellNorthWest(CellId(centerCell.x + 1, centerCell.y + 1)));
    final cellSidePx = (cellSePx.dx - cellNwPx.dx).abs();
    // Radio generoso (~1 celda): cuanto más se solapan los círculos de celdas
    // vecinas, más liso y redondeado queda el contorno general (menos "grumos").
    final radius = cellSidePx * 1.0;

    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cellSidePx * 0.28);

    for (final cell in controller.discovered) {
      final nw = cellNorthWest(cell);
      final se = cellNorthWest(CellId(cell.x + 1, cell.y + 1));

      // Culling: saltar celdas que no se ven en pantalla.
      if (se.latitude > visible.north ||
          nw.latitude < visible.south ||
          nw.longitude > visible.east ||
          se.longitude < visible.west) {
        continue;
      }

      final topLeft = camera.latLngToScreenOffset(nw);
      final bottomRight = camera.latLngToScreenOffset(se);
      final center = Offset(
        (topLeft.dx + bottomRight.dx) / 2,
        (topLeft.dy + bottomRight.dy) / 2,
      );
      canvas.drawCircle(center, radius, clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
}
