// Capa visual del fog of war.
//
// Se coloca como hija de FlutterMap, encima de los tiles del mapa. Pinta un
// velo gris que cubre toda la pantalla y luego "recorta" (borra) las celdas
// que el jugador ya ha descubierto, dejando ver el mapa debajo. Por encima,
// dibuja un ribete del color del jugador justo en el límite entre lo
// descubierto y la niebla.

import 'dart:ui' show ImageFilter, TileMode;

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
    // RepaintBoundary: aísla el repintado de la niebla en su propia capa, para
    // que sus redibujados (en cada movimiento de cámara) no obliguen a re-pintar
    // a los hermanos (marcadores, etc.).
    return RepaintBoundary(
      child: CustomPaint(
        size: camera.nonRotatedSize,
        painter: _FogPainter(
          camera: camera,
          controller: controller,
          color: color,
          borderColor: borderColor,
        ),
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

    // Si no hay ninguna celda visible, todo es niebla: un simple rectángulo
    // (sin capas ni desenfoques) y listo.
    if (centers.isEmpty) {
      canvas.drawRect(fullRect, Paint()..color = color);
      return;
    }

    // El contorno de la unión de celdas (un círculo por celda) sale
    // "festoneado": se notan las protuberancias de cada celda. Para un borde
    // SUAVE y continuo usamos el efecto metaball/goo: se difumina la unión de
    // círculos y se aplica un UMBRAL de opacidad (colorFilter) que vuelve a dar
    // un borde nítido pero ya redondeado, fundido entre celdas vecinas.
    final gooSigma = cellSidePx * 0.55;
    final metaRadius = cellSidePx * 0.70;
    // Pendiente del umbral: alta = transición estrecha (borde definido).
    const slope = 26.0;
    // Opacidad a la que cae el borde del agujero. La versión erosionada (para el
    // grosor del ribete) usa un umbral más alto → mancha algo más pequeña.
    const cutEdge = 0.5;
    const cutInner = 0.62;

    // CLAVE DE RENDIMIENTO: en vez de un MaskFilter.blur por celda (cientos de
    // desenfoques por frame), se dibujan los círculos NÍTIDOS en una capa y se
    // desenfoca esa capa UNA sola vez (ImageFilter.blur). El umbral posterior
    // recupera el mismo borde redondeado. Visualmente equivalente, mucho más
    // barato. TileMode.decal trata el exterior de la capa como transparente
    // (como el viejo MaskFilter), sin sangrado en los bordes de pantalla.
    final blur = ImageFilter.blur(
        sigmaX: gooSigma, sigmaY: gooSigma, tileMode: TileMode.decal);

    // Compone en la capa actual la mancha metaball (unión nítida → 1 desenfoque
    // → umbral). [composite] aporta blendMode/alpha; [cut] fija a qué opacidad
    // cae el borde (más alto = mancha algo más pequeña / erosionada); [fill] es
    // el color de los círculos (su RGB sobrevive al umbral).
    void drawMetaball(Paint composite, double cut, Color fill) {
      composite.colorFilter = _alphaThreshold(slope: slope, cut: cut);
      canvas.saveLayer(fullRect, composite);
      canvas.saveLayer(fullRect, Paint()..imageFilter = blur);
      final circle = Paint()..color = fill;
      for (final center in centers) {
        canvas.drawCircle(center, metaRadius, circle);
      }
      canvas.restore();
      canvas.restore();
    }

    // 1) Velo de niebla con agujeros de contorno suave (la mancha se RESTA del
    // velo con dstOut; el color de los círculos da igual, solo cuenta su alpha).
    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(fullRect, Paint()..color = color);
    drawMetaball(
        Paint()..blendMode = BlendMode.dstOut, cutEdge, const Color(0xFFFFFFFF));
    canvas.restore();

    // 2) Ribete suave del color elegido en el límite descubierto/niebla.
    //
    // Mismo metaball, pero como ANILLO: la mancha del color menos una versión
    // erosionada (umbral más alto = mancha algo menor). La diferencia es una
    // línea de grosor uniforme que sigue el contorno suave.
    if (borderColor != null) {
      canvas.saveLayer(fullRect, Paint());
      drawMetaball(Paint(), cutEdge, borderColor!);
      drawMetaball(Paint()..blendMode = BlendMode.dstOut, cutInner,
          const Color(0xFFFFFFFF));
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
