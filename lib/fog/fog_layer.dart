// Capa visual del fog of war.
//
// Se coloca como hija de FlutterMap, encima de los tiles del mapa. Pinta un
// velo gris que cubre toda la pantalla y luego "recorta" (borra) las celdas
// que el jugador ya ha descubierto, dejando ver el mapa debajo. Por encima,
// dibuja un ribete del color del jugador justo en el límite entre lo
// descubierto y la niebla.

import 'dart:ui' as ui;
import 'dart:ui' show ClipOp, ImageFilter, TileMode;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'fog_controller.dart';
import 'tile_math.dart';

/// Color del velo de niebla (gris azulado oscuro, bastante opaco).
const Color kFogColor = Color(0xEC262A32);

/// Tamaño de celda (en píxeles de pantalla) por debajo del cual la máscara de
/// niebla se rinde a baja resolución y se reescala (mismo borde suave, pero el
/// desenfoque trabaja sobre muchos menos píxeles). A ~38 m por celda esto cae
/// alrededor del zoom 15-16: por encima, máscara a resolución nativa; por debajo
/// (zoom alejado, muchas celdas visibles) prima el rendimiento sin perder el look.
const double _kMetaballMinCellPx = 16.0;

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
    // vez y se reutilizan para el velo y para el ribete. De paso se acumula la
    // caja envolvente (en pantalla) de todos esos centros.
    final visible = camera.visibleBounds;
    final centers = <Offset>[];
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
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
      final cx = (topLeft.dx + bottomRight.dx) / 2;
      final cy = (topLeft.dy + bottomRight.dy) / 2;
      centers.add(Offset(cx, cy));
      if (cx < minX) minX = cx;
      if (cx > maxX) maxX = cx;
      if (cy < minY) minY = cy;
      if (cy > maxY) maxY = cy;
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

    // RUTA RÁPIDA (zoom alejado): el MISMO borde suave, pero barato. Al alejar se
    // ven muchísimas celdas a la vez y desenfocarlas a (casi) pantalla completa
    // cada frame es el peor tirón. Como el desenfoque es un efecto de baja
    // frecuencia, rendimos la máscara metaball a baja resolución y la reescalamos:
    // se ve igual de suave, pero el blur trabaja sobre N veces menos píxeles. El
    // umbral (slope/cutEdge) es idéntico al de cerca, así que no hay salto visible
    // al cruzar el umbral de zoom.
    if (cellSidePx < _kMetaballMinCellPx) {
      final margin = metaRadius + gooSigma * 3;
      final bounds = Rect.fromLTRB(
        minX - margin,
        minY - margin,
        maxX + margin,
        maxY + margin,
      ).intersect(fullRect);

      // Factor de reducción: cuanto mayor el desenfoque, más se puede reducir sin
      // que se note (mantenemos ~2 px de sigma en la máscara pequeña).
      final scale = (gooSigma / 2.0).clamp(1.0, 4.0);
      final w = (bounds.width / scale).ceil().clamp(1, 4096);
      final h = (bounds.height / scale).ceil().clamp(1, 4096);

      // En la imagen pequeña horneamos SOLO el desenfoque (lo caro), no el
      // umbral: círculos blancos + 1 blur. El umbral se deja para resolución
      // completa (abajo), que es lo que da un borde nítido sin importar cuánto se
      // reescale. Si se umbralizara aquí, el reescalado ×N ensancharía el borde y
      // se vería blando.
      final recorder = ui.PictureRecorder();
      final maskCanvas = Canvas(recorder);
      final maskRect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
      maskCanvas.saveLayer(
        maskRect,
        Paint()
          ..imageFilter = ImageFilter.blur(
              sigmaX: gooSigma / scale,
              sigmaY: gooSigma / scale,
              tileMode: TileMode.decal),
      );
      final circle = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..isAntiAlias = true;
      for (final center in centers) {
        maskCanvas.drawCircle(
          Offset((center.dx - bounds.left) / scale,
              (center.dy - bounds.top) / scale),
          metaRadius / scale,
          circle,
        );
      }
      maskCanvas.restore();
      final mask = recorder.endRecording().toImageSync(w, h);

      final fog = Paint()..color = color;
      // Fuera de la caja, velo plano sin agujeros (sin capa).
      canvas.save();
      canvas.clipRect(bounds, clipOp: ClipOp.difference);
      canvas.drawRect(fullRect, fog);
      canvas.restore();

      // Dentro, el velo con los agujeros restados. El umbral (que da el borde
      // nítido) se aplica a RESOLUCIÓN COMPLETA en el saveLayer que también hace
      // el dstOut: dentro se dibuja la máscara difuminada reescalada (normal), y
      // al cerrar la capa se umbraliza y se resta del velo. Es el mismo patrón
      // que funciona de cerca (umbral + dstOut sobre una capa, no sobre la
      // imagen), así que no reaparece el blanco.
      canvas.saveLayer(bounds, Paint());
      canvas.drawRect(bounds, fog);
      canvas.saveLayer(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..colorFilter = _alphaThreshold(slope: slope, cut: cutEdge),
      );
      canvas.drawImageRect(
        mask,
        maskRect,
        bounds,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
      canvas.restore();
      mask.dispose();
      return;
    }

    // CLAVE DE RENDIMIENTO: en vez de un MaskFilter.blur por celda (cientos de
    // desenfoques por frame), se dibujan los círculos NÍTIDOS en una capa y se
    // desenfoca esa capa UNA sola vez (ImageFilter.blur). El umbral posterior
    // recupera el mismo borde redondeado. Visualmente equivalente, mucho más
    // barato. TileMode.decal trata el exterior de la capa como transparente
    // (como el viejo MaskFilter), sin sangrado en los bordes de pantalla.
    final blur = ImageFilter.blur(
        sigmaX: gooSigma, sigmaY: gooSigma, tileMode: TileMode.decal);

    // CLAVE DE RENDIMIENTO: el blur y los saveLayer son lo más caro de la GPU y
    // su coste es proporcional al área de la capa. En vez de trabajar sobre toda
    // la pantalla, acotamos todo a la caja que envuelve las celdas visibles más
    // un margen que cubre el radio del círculo y el alcance del desenfoque (~3
    // sigmas). Fuera de esa caja solo hay velo plano (baratísimo). Si lo
    // descubierto cubre toda la pantalla, la caja es la pantalla y no se pierde
    // nada; si cubre solo un trozo (lo normal al pasear), el ahorro es enorme.
    final margin = metaRadius + gooSigma * 3;
    final blobBounds = Rect.fromLTRB(
      minX - margin,
      minY - margin,
      maxX + margin,
      maxY + margin,
    ).intersect(fullRect);

    // Compone en la capa actual la mancha metaball (unión nítida → 1 desenfoque
    // → umbral), acotada a [blobBounds]. [composite] aporta blendMode/alpha;
    // [cut] fija a qué opacidad cae el borde (más alto = mancha algo más pequeña
    // / erosionada); [fill] es el color de los círculos (su RGB sobrevive al
    // umbral).
    void drawMetaball(Paint composite, double cut, Color fill) {
      composite.colorFilter = _alphaThreshold(slope: slope, cut: cut);
      canvas.saveLayer(blobBounds, composite);
      canvas.saveLayer(blobBounds, Paint()..imageFilter = blur);
      final circle = Paint()..color = fill;
      for (final center in centers) {
        canvas.drawCircle(center, metaRadius, circle);
      }
      canvas.restore();
      canvas.restore();
    }

    // 1) Velo de niebla con agujeros de contorno suave.
    //
    // Fuera de la caja del blob, el velo es un rectángulo plano sin agujeros: lo
    // pintamos directo recortando la caja (clip de diferencia), sin capas.
    final fogPaint = Paint()..color = color;
    canvas.save();
    canvas.clipRect(blobBounds, clipOp: ClipOp.difference);
    canvas.drawRect(fullRect, fogPaint);
    canvas.restore();

    // Dentro de la caja, el velo con los agujeros restados (la mancha se RESTA
    // del velo con dstOut; el color de los círculos da igual, solo su alpha). El
    // velo del parche usa el mismo color/alpha que el de fuera, así que el borde
    // de la caja no se nota (cobertura única a ambos lados).
    canvas.saveLayer(blobBounds, Paint());
    canvas.drawRect(blobBounds, fogPaint);
    drawMetaball(
        Paint()..blendMode = BlendMode.dstOut, cutEdge, const Color(0xFFFFFFFF));
    canvas.restore();

    // 2) Ribete suave del color elegido en el límite descubierto/niebla.
    //
    // Mismo metaball, pero como ANILLO: la mancha del color menos una versión
    // erosionada (umbral más alto = mancha algo menor). La diferencia es una
    // línea de grosor uniforme que sigue el contorno suave.
    if (borderColor != null) {
      canvas.saveLayer(blobBounds, Paint());
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
