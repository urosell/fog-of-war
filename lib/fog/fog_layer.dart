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

  const FogLayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // MapCamera.of registra esta capa como dependiente de la cámara: cuando el
    // mapa se mueve o hace zoom, este build se vuelve a ejecutar.
    final camera = MapCamera.of(context);
    return CustomPaint(
      size: camera.nonRotatedSize,
      painter: _FogPainter(camera: camera, controller: controller),
    );
  }
}

class _FogPainter extends CustomPainter {
  final MapCamera camera;
  final FogController controller;

  // Pasar el controller como 'repaint' hace que el painter se redibuje cuando
  // se descubren celdas nuevas (cuando llama a notifyListeners()).
  _FogPainter({required this.camera, required this.controller})
      : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    // saveLayer aísla el dibujo para poder "borrar" con BlendMode.clear.
    canvas.saveLayer(fullRect, Paint());

    // 1) Velo gris cubriendo toda la pantalla.
    canvas.drawRect(fullRect, Paint()..color = kFogColor);

    // 2) Borrar cada celda descubierta que sea visible en pantalla.
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final visible = camera.visibleBounds;

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
      // Inflamos medio píxel para que celdas contiguas no dejen líneas de niebla.
      final rect = Rect.fromPoints(topLeft, bottomRight).inflate(0.5);
      canvas.drawRect(rect, clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
}
