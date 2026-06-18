// Capa visual del fog of war.
//
// Se coloca como hija de FlutterMap, encima de los tiles del mapa. Pinta un
// velo gris que cubre toda la pantalla y luego "recorta" (borra) las celdas
// que el jugador ya ha descubierto, dejando ver el mapa debajo. Por encima,
// dibuja un ribete del color del jugador justo en el límite entre lo
// descubierto y la niebla.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'fog_controller.dart';
import 'tile_math.dart';

/// Color del velo de niebla (gris azulado oscuro, bastante opaco).
const Color kFogColor = Color(0xEC262A32);

class FogLayer extends StatelessWidget {
  final FogController controller;

  /// Color del velo de niebla. Por defecto, el gris azulado del juego; cada
  /// estilo de mapa puede pasar el suyo para que pegue con el mapa de fondo.
  final Color color;

  /// Color del ribete que marca el límite descubierto/niebla. Suele ser el
  /// color elegido por el jugador (el de su avatar). Si es null, no se dibuja.
  final Color? borderColor;

  const FogLayer({
    super.key,
    required this.controller,
    this.color = kFogColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // MapCamera.of registra esta capa como dependiente de la cámara: cuando el
    // mapa se mueve o hace zoom, este build se vuelve a ejecutar.
    final camera = MapCamera.of(context);
    return CustomPaint(
      size: camera.nonRotatedSize,
      painter: _FogPainter(
        camera: camera,
        controller: controller,
        color: color,
        borderColor: borderColor,
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  final MapCamera camera;
  final FogController controller;
  final Color color;
  final Color? borderColor;

  // Pasar el controller como 'repaint' hace que el painter se redibuje cuando
  // se descubren celdas nuevas (cuando llama a notifyListeners()).
  _FogPainter({
    required this.camera,
    required this.controller,
    required this.color,
    this.borderColor,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    // Tamaño en pantalla de una celda a este zoom (es constante en todo el mapa
    // para un zoom dado). Lo usamos para el radio y el desenfoque.
    final centerCell = cellForLatLng(camera.center);
    final cellNwPx = camera.latLngToScreenOffset(cellNorthWest(centerCell));
    final cellSePx = camera.latLngToScreenOffset(
        cellNorthWest(CellId(centerCell.x + 1, centerCell.y + 1)));
    final cellSidePx = (cellSePx.dx - cellNwPx.dx).abs();

    // Centros (en pantalla) de cada celda descubierta visible. Se calculan una
    // vez y se reutilizan para el velo y para el ribete.
    final visible = camera.visibleBounds;
    final centers = <Offset>[];
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
      centers.add(Offset(
        (topLeft.dx + bottomRight.dx) / 2,
        (topLeft.dy + bottomRight.dy) / 2,
      ));
    }

    // El contorno de la unión de celdas (un círculo por celda) sale
    // "festoneado": se notan las protuberancias de cada celda. Para un borde
    // SUAVE y continuo usamos el efecto metaball/goo: se difuminan los círculos
    // y se aplica un UMBRAL de opacidad (colorFilter) que vuelve a dar un borde
    // nítido pero ya redondeado, fundido entre celdas vecinas. El umbral se
    // aplica al componer la capa.
    final gooSigma = cellSidePx * 0.55;
    final metaRadius = cellSidePx * 0.70;
    final blurPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, gooSigma);
    // Pendiente del umbral: alta = transición estrecha (borde definido).
    const slope = 26.0;
    // Opacidad a la que cae el borde del agujero. La versión erosionada (para el
    // grosor del ribete) usa un umbral más alto → mancha algo más pequeña.
    const cutEdge = 0.5;
    const cutInner = 0.62;

    // 1) Velo de niebla con agujeros de contorno suave.
    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(fullRect, Paint()..color = color);
    // Capa "borrador": mancha difuminada → el umbral la vuelve sólida con borde
    // redondeado → dstOut la recorta de la niebla.
    canvas.saveLayer(
      fullRect,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..colorFilter = _alphaThreshold(slope: slope, cut: cutEdge),
    );
    for (final center in centers) {
      canvas.drawCircle(center, metaRadius, blurPaint);
    }
    canvas.restore();
    canvas.restore();

    // 2) Ribete suave del color elegido en el límite descubierto/niebla.
    //
    // Mismo metaball, pero como ANILLO: se pinta la mancha del color con el
    // umbral del borde y se le RESTA una versión erosionada (umbral más alto =
    // mancha algo menor). La diferencia es una línea de grosor uniforme que
    // sigue el contorno suave.
    if (borderColor != null && centers.isNotEmpty) {
      canvas.saveLayer(fullRect, Paint());
      // Mancha del color con contorno suave (coincide con el del agujero).
      canvas.saveLayer(
        fullRect,
        Paint()..colorFilter = _alphaThreshold(slope: slope, cut: cutEdge),
      );
      final coloredBlur = Paint()
        ..color = borderColor!
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, gooSigma);
      for (final center in centers) {
        canvas.drawCircle(center, metaRadius, coloredBlur);
      }
      canvas.restore();
      // Restar la mancha erosionada (umbral más alto) → queda solo el anillo.
      canvas.saveLayer(
        fullRect,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..colorFilter = _alphaThreshold(slope: slope, cut: cutInner),
      );
      for (final center in centers) {
        canvas.drawCircle(center, metaRadius, blurPaint);
      }
      canvas.restore();
      canvas.restore();
    }
  }

  // La cámara cambia en cada movimiento/zoom y crea un painter nuevo; repintamos
  // siempre para seguir el mapa (el contorno se recalcula respecto a pantalla).
  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
}

/// ColorFilter que convierte una mancha difuminada en una forma sólida de borde
/// nítido (efecto metaball): alpha_out = slope·(alpha − cut). Con [slope] alto
/// la transición es estrecha (borde definido); [cut] elige a qué opacidad cae el
/// borde (más alto = forma más pequeña / erosionada). Mantiene el color RGB.
ColorFilter _alphaThreshold({required double slope, required double cut}) {
  return ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, slope, -slope * cut * 255, //
  ]);
}
