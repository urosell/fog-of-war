// Capa visual del fog of war.
//
// Se coloca como hija de FlutterMap, encima de los tiles del mapa. Pinta un
// velo gris que cubre toda la pantalla y luego "recorta" (borra) las celdas
// que el jugador ya ha descubierto, dejando ver el mapa debajo. El contorno
// de lo descubierto es suave y redondeado (efecto metaball): un círculo por
// celda, difuminado y umbralizado.
//
// CÓMO SE CONSIGUE QUE SEA FLUIDO
//
// El desenfoque que da el borde suave es lo más caro de la GPU, y regenerarlo
// en cada frame mientras se arrastra o hace zoom es lo que atascaba la app.
// La clave es NO regenerarlo por frame:
//
//  1. La mancha difuminada se hornea UNA vez en una imagen (la "máscara"),
//     anclada al grid de celdas y con un margen de sobrebarrido alrededor de
//     lo visible. En cada frame solo se dibuja esa imagen desplazada/escalada
//     (baratísimo). El umbral que convierte el difuminado en un borde nítido
//     se aplica al vuelo a resolución de pantalla, así que el borde no se
//     ablanda por reescalar la máscara. Solo se rehornea cuando se descubren
//     celdas nuevas, cuando el arrastre se sale del sobrebarrido o cuando el
//     zoom acerca tanto que hace falta más resolución.
//
//  2. Para reunir las celdas de la máscara no se recorren todas las
//     descubiertas: el FogController las indexa por tile Z16 y aquí solo se
//     visitan los tiles del área a hornear.
//
//  3. El grid de celdas es mercator puro, así que celda→pantalla es una
//     transformación afín: se proyectan 3 esquinas de una celda de referencia
//     (vale también con el mapa rotado) y el resto son sumas, sin
//     trigonometría por celda.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show ClipOp, ImageFilter, TileMode;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'fog_controller.dart';
import 'tile_math.dart';

/// Color del velo de niebla (gris azulado oscuro, bastante opaco).
const Color kFogColor = Color(0xEC262A32);

// Geometría del metaball en unidades de CELDA (así es idéntica a todo zoom):
// radio del círculo por celda y sigma del desenfoque que funde celdas vecinas.
const double _kMetaRadiusCells = 0.70;
const double _kGooSigmaCells = 0.55;
// Pendiente del umbral: alta = transición estrecha (borde definido).
const double _kSlope = 26.0;
// Opacidad a la que cae el borde del agujero. La versión erosionada (para el
// grosor del ribete) usa un umbral más alto → mancha algo más pequeña.
const double _kCutEdge = 0.5;
const double _kCutInner = 0.62;

// Alcance visual de una celda (radio + cola del desenfoque, ~3 sigmas), en
// celdas. Es el margen que se usa en todos los cálculos de cajas.
const double _kReachCells = _kMetaRadiusCells + 3 * _kGooSigmaCells;

// Resolución mínima de la máscara (px por celda): la que deja el sigma del
// desenfoque en ~2 px, de sobra para una forma tan de baja frecuencia.
const double _kMinMaskPxPerCell = 2.0 / _kGooSigmaCells;

// Tope de reescalado máscara→pantalla. De cerca la máscara se hornea con más
// resolución para que el borde interpolado no se note poligonal.
const double _kMaxMaskUpscale = 8.0;

// Lado máximo de la imagen de máscara, en píxeles.
const int _kMaskMaxDim = 2048;

// Sobrebarrido: cuánto se agranda la máscara respecto a lo necesario (fracción
// por lado). Más grande = más arrastre sin rehornear, a cambio de memoria.
const double _kOverscanFraction = 0.4;

class FogLayer extends StatefulWidget {
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
  State<FogLayer> createState() => _FogLayerState();
}

class _FogLayerState extends State<FogLayer> {
  // La máscara horneada vive en el State para sobrevivir a los rebuilds que
  // provoca cada movimiento de cámara (el painter se recrea; la caché no).
  final _MaskCache _cache = _MaskCache();

  @override
  void dispose() {
    _cache.dispose();
    super.dispose();
  }

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
          controller: widget.controller,
          color: widget.color,
          borderColor: widget.borderColor,
          cache: _cache,
        ),
      ),
    );
  }
}

// Máscara metaball horneada: la mancha difuminada (círculos blancos + blur),
// SIN umbralizar, en una imagen anclada al grid de celdas.
class _MaskCache {
  ui.Image? image;

  // Zona que cubre la imagen, en coordenadas de celda Z20.
  Rect cellRect = Rect.zero;

  // Caja envolvente de los centros de las celdas dibujadas (en celdas), o
  // null si no había ninguna celda descubierta en la zona.
  Rect? contentCellRect;

  // Resolución real de la imagen (px por celda) y la ideal que se pidió al
  // hornear (puede ser mayor si hubo que recortar por el tope de tamaño).
  double pxPerCell = 1;
  double idealPxPerCell = 1;

  // Revisión del FogController con la que se horneó.
  int revision = -1;

  bool baked = false;

  void dispose() {
    image?.dispose();
    image = null;
    baked = false;
  }
}

class _FogPainter extends CustomPainter {
  final MapCamera camera;
  final FogController controller;
  final Color color;
  final Color? borderColor;
  final _MaskCache cache;

  // Pasar el controller como 'repaint' hace que el painter se redibuje cuando
  // se descubren celdas nuevas (cuando llama a notifyListeners()).
  _FogPainter({
    required this.camera,
    required this.controller,
    required this.color,
    required this.cache,
    this.borderColor,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    // Base afín celda→pantalla: 3 esquinas de una celda de referencia cercana
    // al centro. Cualquier celda (x, y) cae en origen + x'·ux + y'·uy.
    final refCell = cellForLatLng(camera.center);
    final origin = camera.latLngToScreenOffset(cellNorthWest(refCell));
    final ux = camera.latLngToScreenOffset(
            cellNorthWest(CellId(refCell.x + 1, refCell.y))) -
        origin;
    final uy = camera.latLngToScreenOffset(
            cellNorthWest(CellId(refCell.x, refCell.y + 1))) -
        origin;
    final cellSidePx = ux.distance;

    Offset cellToScreen(double x, double y) =>
        origin + ux * (x - refCell.x) + uy * (y - refCell.y);

    // Rango de celdas que la máscara debe cubrir: lo visible más el alcance
    // del borde suave (para que al arrastrar no asomen bordes a medio hacer).
    final visible = camera.visibleBounds;
    final nwCell = cellForLatLng(LatLng(visible.north, visible.west));
    final seCell = cellForLatLng(LatLng(visible.south, visible.east));
    final needed = Rect.fromLTRB(
      nwCell.x - _kReachCells,
      nwCell.y - _kReachCells,
      seCell.x + 1 + _kReachCells,
      seCell.y + 1 + _kReachCells,
    );

    // Resolución deseada (px por celda): la mínima del sigma ~2 px, subiendo
    // de cerca para no reescalar más de 8x, y nunca por encima de la nativa.
    final idealPxPerCell = math.min(
      cellSidePx,
      math.max(_kMinMaskPxPerCell, cellSidePx / _kMaxMaskUpscale),
    );

    // ¿Sigue valiendo la máscara horneada? Solo se rehace si cambiaron las
    // celdas, si lo visible se sale de ella o si pide bastante más resolución
    // (un 50% de margen evita rehornear en cada tick del gesto de zoom).
    final needsBake = !cache.baked ||
        cache.revision != controller.revision ||
        !_covers(cache.cellRect, needed) ||
        idealPxPerCell > cache.idealPxPerCell * 1.5;
    if (needsBake) {
      _bakeMask(needed, idealPxPerCell);
    }

    final fogPaint = Paint()..color = color;
    final content = cache.contentCellRect;
    if (content == null) {
      // Nada descubierto por aquí: todo es niebla, un rectángulo y listo.
      canvas.drawRect(fullRect, fogPaint);
      return;
    }

    // Caja en pantalla que envuelve lo descubierto (más el alcance del borde):
    // fuera de ella solo hay velo plano barato; dentro, la capa con agujeros.
    final reach = content.inflate(_kReachCells);
    final r1 = cellToScreen(reach.left, reach.top);
    final r2 = cellToScreen(reach.right, reach.top);
    final r3 = cellToScreen(reach.left, reach.bottom);
    final r4 = cellToScreen(reach.right, reach.bottom);
    final blobBounds = Rect.fromLTRB(
      math.min(math.min(r1.dx, r2.dx), math.min(r3.dx, r4.dx)),
      math.min(math.min(r1.dy, r2.dy), math.min(r3.dy, r4.dy)),
      math.max(math.max(r1.dx, r2.dx), math.max(r3.dx, r4.dx)),
      math.max(math.max(r1.dy, r2.dy), math.max(r3.dy, r4.dy)),
    ).intersect(fullRect);
    if (blobBounds.isEmpty) {
      canvas.drawRect(fullRect, fogPaint);
      return;
    }

    // 1) Fuera de la caja, velo plano sin agujeros (sin capas).
    canvas.save();
    canvas.clipRect(blobBounds, clipOp: ClipOp.difference);
    canvas.drawRect(fullRect, fogPaint);
    canvas.restore();

    // Transformación para dibujar la máscara: el destino se expresa en
    // unidades de celda relativas a la esquina de la máscara. La traslación se
    // calcula en CPU (doble precisión) para que las coordenadas absolutas de
    // celda (~10^5) no pasen por los floats de la GPU.
    final maskOrigin = cellToScreen(cache.cellRect.left, cache.cellRect.top);
    final matrix = Matrix4(
      ux.dx, ux.dy, 0, 0, //
      uy.dx, uy.dy, 0, 0, //
      0, 0, 1, 0, //
      maskOrigin.dx, maskOrigin.dy, 0, 1, //
    );
    final image = cache.image!;
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(
        0, 0, image.width / cache.pxPerCell, image.height / cache.pxPerCell);

    // Dibuja la máscara cacheada dentro de un saveLayer cuyo Paint aplica el
    // umbral (borde nítido a resolución de pantalla, por eso reescalar la
    // máscara no lo ablanda) y el modo de mezcla al componer la capa. Es el
    // mismo patrón que ya funcionaba antes: umbral + blend sobre una CAPA, no
    // sobre la imagen directamente (Impeller no compone bien esto último).
    void drawMask(BlendMode mode, double cut, {Color? tint}) {
      canvas.saveLayer(
        blobBounds,
        Paint()
          ..blendMode = mode
          ..colorFilter = tint == null
              ? _alphaThreshold(slope: _kSlope, cut: cut)
              : _tintThreshold(tint: tint, slope: _kSlope, cut: cut),
      );
      canvas.transform(matrix.storage);
      canvas.drawImageRect(
          image, src, dst, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    }

    // 2) Dentro de la caja, el velo con los agujeros restados: la máscara
    // umbralizada se resta del velo (dstOut). El velo del parche usa el mismo
    // color que el de fuera, así que el borde de la caja no se nota (cobertura
    // única a ambos lados).
    canvas.saveLayer(blobBounds, Paint());
    canvas.drawRect(blobBounds, fogPaint);
    drawMask(BlendMode.dstOut, _kCutEdge);
    canvas.restore();

    // 3) Ribete suave del color elegido en el límite descubierto/niebla: la
    // mancha teñida menos su versión erosionada (umbral más alto) deja un
    // anillo de grosor uniforme que sigue el contorno.
    if (borderColor != null) {
      canvas.saveLayer(blobBounds, Paint());
      drawMask(BlendMode.srcOver, _kCutEdge, tint: borderColor);
      drawMask(BlendMode.dstOut, _kCutInner);
      canvas.restore();
    }
  }

  // Hornea la máscara: círculos blancos nítidos (uno por celda descubierta)
  // difuminados UNA vez con un solo blur. Sin umbral: ese se aplica al dibujar,
  // a resolución de pantalla.
  void _bakeMask(Rect needed, double idealPxPerCell) {
    // Sobrebarrido alrededor de lo necesario, redondeado a celdas enteras.
    final rect = Rect.fromLTRB(
      (needed.left - needed.width * _kOverscanFraction).floorToDouble(),
      (needed.top - needed.height * _kOverscanFraction).floorToDouble(),
      (needed.right + needed.width * _kOverscanFraction).ceilToDouble(),
      (needed.bottom + needed.height * _kOverscanFraction).ceilToDouble(),
    );

    // Si la imagen saldría demasiado grande (zoom muy alejado, miles de celdas
    // a la vista), se baja la resolución para respetar el tope.
    var pxPerCell = idealPxPerCell;
    final maxSideCells = math.max(rect.width, rect.height);
    if (maxSideCells * pxPerCell > _kMaskMaxDim) {
      pxPerCell = _kMaskMaxDim / maxSideCells;
    }

    final w = (rect.width * pxPerCell).ceil().clamp(1, _kMaskMaxDim);
    final h = (rect.height * pxPerCell).ceil().clamp(1, _kMaskMaxDim);
    final recorder = ui.PictureRecorder();
    final maskCanvas = Canvas(recorder);
    final sigma = _kGooSigmaCells * pxPerCell;
    maskCanvas.saveLayer(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()
        ..imageFilter = ImageFilter.blur(
            sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
    );
    final circle = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = true;

    // Solo se visitan los tiles Z16 que tocan la máscara; de cada uno, sus
    // celdas descubiertas. De paso se acumula la caja envolvente del contenido.
    final byTile = controller.discoveredByTile;
    final minTileX = (rect.left / kCellsPerTileSide).floor();
    final maxTileX = ((rect.right - 1) / kCellsPerTileSide).floor();
    final minTileY = (rect.top / kCellsPerTileSide).floor();
    final maxTileY = ((rect.bottom - 1) / kCellsPerTileSide).floor();
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    var any = false;
    for (var ty = minTileY; ty <= maxTileY; ty++) {
      for (var tx = minTileX; tx <= maxTileX; tx++) {
        final cells = byTile[TileId(tx, ty)];
        if (cells == null) continue;
        for (final cell in cells) {
          final cx = cell.x + 0.5;
          final cy = cell.y + 0.5;
          if (cx < rect.left ||
              cx > rect.right ||
              cy < rect.top ||
              cy > rect.bottom) {
            continue;
          }
          any = true;
          if (cx < minX) minX = cx;
          if (cx > maxX) maxX = cx;
          if (cy < minY) minY = cy;
          if (cy > maxY) maxY = cy;
          maskCanvas.drawCircle(
            Offset((cx - rect.left) * pxPerCell, (cy - rect.top) * pxPerCell),
            _kMetaRadiusCells * pxPerCell,
            circle,
          );
        }
      }
    }
    maskCanvas.restore();
    final picture = recorder.endRecording();

    cache.image?.dispose();
    cache.image = any ? picture.toImageSync(w, h) : null;
    picture.dispose();
    cache.contentCellRect =
        any ? Rect.fromLTRB(minX, minY, maxX, maxY) : null;
    cache.cellRect = rect;
    cache.pxPerCell = pxPerCell;
    cache.idealPxPerCell = idealPxPerCell;
    cache.revision = controller.revision;
    cache.baked = true;
  }

  // La cámara cambia en cada movimiento/zoom y crea un painter nuevo; repintamos
  // siempre para seguir el mapa (la máscara cacheada hace que sea barato).
  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) => true;
}

bool _covers(Rect outer, Rect inner) =>
    outer.left <= inner.left &&
    outer.top <= inner.top &&
    outer.right >= inner.right &&
    outer.bottom >= inner.bottom;

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

/// Igual que [_alphaThreshold], pero además pinta la forma del color [tint]
/// (para el ribete: la máscara horneada es blanca y aquí se tiñe al dibujar).
ColorFilter _tintThreshold(
    {required Color tint, required double slope, required double cut}) {
  return ColorFilter.matrix(<double>[
    0, 0, 0, 0, tint.r * 255, //
    0, 0, 0, 0, tint.g * 255, //
    0, 0, 0, 0, tint.b * 255, //
    0, 0, 0, slope, -slope * cut * 255, //
  ]);
}
