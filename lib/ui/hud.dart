// Piezas visuales del HUD (la interfaz que va flotando sobre el mapa).
//
// Todo el HUD usa un efecto de "cristal esmerilado" (frosted glass): se desenfoca
// lo que hay detrás (el mapa) y se le pone encima una capa oscura translúcida con
// un gradiente sutil, un brillo en el borde superior y una sombra exterior. Esto
// le da profundidad (parece vidrio físico flotando) y un aspecto de videojuego.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';

/// Color de acento principal del HUD (un turquesa brillante).
const Color kHudAccent = Color(0xFF4DE3C2);

/// Acentos secundarios para distinguir cada estadística de un vistazo.
const Color kHudGold = Color(0xFFFFD166); // puntos
const Color kHudCoral = Color(0xFFFF7A9C); // POIs

/// Decoración de cristal compartida por paneles y botones: gradiente vertical
/// (más claro arriba, como el reflejo de un vidrio), borde fino luminoso y, si
/// se pasa [glow], un halo de color para señalar un estado activo.
BoxDecoration _glassDecoration({
  required BorderRadius radius,
  Color? glow,
}) {
  return BoxDecoration(
    borderRadius: radius,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.16),
        Colors.black.withValues(alpha: 0.34),
        Colors.black.withValues(alpha: 0.46),
      ],
      stops: const [0.0, 0.55, 1.0],
    ),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.24),
      width: 1,
    ),
    boxShadow: [
      // Sombra que despega el panel del mapa.
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
      // Halo de color opcional (botón/estado activo).
      if (glow != null)
        BoxShadow(
          color: glow.withValues(alpha: 0.45),
          blurRadius: 16,
          spreadRadius: 1,
        ),
    ],
  );
}

/// Panel rectangular con esquinas redondeadas y efecto cristal esmerilado.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: _glassDecoration(radius: br),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Botón redondo de cristal esmerilado con un icono. Si [active] es true, se
/// resalta con el color de acento y un halo (para reflejar un estado activado).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool active;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    const br = BorderRadius.all(Radius.circular(26));
    final boton = DecoratedBox(
      decoration: _glassDecoration(
        radius: br,
        glow: active ? kHudAccent : null,
      ).copyWith(
        border: Border.all(
          color: active
              ? kHudAccent.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.24),
          width: active ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  icon,
                  color: active ? kHudAccent : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? boton : Tooltip(message: tooltip!, child: boton);
  }
}

/// Tarjeta de estadísticas: anillo con el % descubierto (el dato estrella) y,
/// al lado, la ciudad con sus tres métricas (celdas, puntos y POIs).
///
/// Si hay una "misión" activa, el tercer indicador deja de mostrar los POIs
/// globales y pasa a mostrar el progreso de la colección fijada (icono y color
/// propios), y toda la tarjeta se vuelve tocable ([onTap]) para abrir esa lista.
class HudStats extends StatelessWidget {
  final String cityName;
  final double percentage;
  final int cells;
  final int points;
  final int poisDiscovered;
  final int poisTotal;

  /// Misión activa (null = sin misión, se muestran los POIs globales).
  final bool missionActive;
  final int missionDiscovered;
  final int missionTotal;
  final Color? missionColor;
  final IconData? missionIcon;
  final String missionLabel;

  /// Si no es null, la tarjeta es tocable (abre la misión fijada).
  final VoidCallback? onTap;

  /// Si no es null, la pulsación larga la ejecuta (quitar la misión fijada).
  final VoidCallback? onLongPress;

  /// Si no es null, tocar el nombre de la ciudad lo ejecuta (abrir "Cities").
  final VoidCallback? onCityTap;

  const HudStats({
    super.key,
    required this.cityName,
    required this.percentage,
    required this.cells,
    required this.points,
    required this.poisDiscovered,
    required this.poisTotal,
    this.missionActive = false,
    this.missionDiscovered = 0,
    this.missionTotal = 0,
    this.missionColor,
    this.missionIcon,
    this.missionLabel = '',
    this.onTap,
    this.onLongPress,
    this.onCityTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final panel = GlassPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProgressRing(percentage: percentage),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CityName(name: cityName, onTap: onCityTap),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Stat(
                    icon: Icons.grid_view_rounded,
                    color: kHudAccent,
                    value: cells,
                    label: l.hudCells,
                  ),
                  const SizedBox(width: 16),
                  _Stat(
                    icon: Icons.star_rounded,
                    color: kHudGold,
                    value: points,
                    label: l.hudPoints,
                  ),
                  const SizedBox(width: 16),
                  // Tercer indicador: misión fijada (su progreso, icono y
                  // color) o, si no hay misión, los POIs globales.
                  if (missionActive)
                    _Stat(
                      icon: missionIcon ?? Icons.flag_rounded,
                      color: missionColor ?? kHudCoral,
                      value: missionDiscovered,
                      total: missionTotal,
                      label: missionLabel,
                    )
                  else
                    _Stat(
                      icon: Icons.place_rounded,
                      color: kHudCoral,
                      value: poisDiscovered,
                      total: poisTotal,
                      label: l.hudPois,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null && onLongPress == null) return panel;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: panel,
    );
  }
}

/// Nombre de la ciudad en el HUD. Si [onTap] no es null, se vuelve tocable
/// (abre la lista de ciudades) y muestra un pequeño chevron como pista visual.
class _CityName extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const _CityName({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
    if (onTap == null) return Text(name, style: style);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name, style: style),
          const SizedBox(width: 3),
          Icon(
            Icons.expand_more_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// Anillo de progreso con el porcentaje descubierto en el centro. Pinta una
/// pista de fondo tenue y el arco de avance en turquesa con punta redondeada.
class _ProgressRing extends StatelessWidget {
  final double percentage; // 0..100

  const _ProgressRing({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox(
      width: 52,
      height: 52,
      // Anima el arco Y el número desde su valor anterior hasta el nuevo, así
      // el progreso "sube" en vez de saltar. Con reduced-motion salta directo.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: percentage, end: percentage),
        duration: Duration(milliseconds: reduced ? 0 : 700),
        curve: Curves.easeOutCubic,
        builder: (context, animPct, _) => CustomPaint(
          painter: _RingPainter(animPct / 100.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  animPct.toStringAsFixed(animPct < 10 ? 2 : 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1

  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Pista de fondo (anillo tenue completo).
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.16);
    canvas.drawCircle(center, radius, track);

    // Arco de avance. Garantizamos un mínimo visible para que nunca parezca
    // "vacío" del todo cuando acabas de empezar a explorar.
    final sweep = math.max(progress, 0.02).clamp(0.0, 1.0) * 2 * math.pi;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [kHudAccent, Color(0xFF7CF5DC), kHudAccent],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Una métrica compacta: mini-icono de color + valor en blanco + etiqueta tenue.
///
/// El [value] (la parte que cambia al jugar) se anima con un "count-up" y, al
/// incrementarse, la métrica da un breve "pop" (escala + brillo del icono) para
/// que el avance se sienta. Si hay un [total], se muestra "value/total" (los
/// POIs y la misión), animando solo el numerador.
class _Stat extends StatefulWidget {
  final IconData icon;
  final Color color;
  final int value;
  final int? total;
  final String label;

  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    this.total,
    required this.label,
  });

  @override
  State<_Stat> createState() => _StatState();
}

class _StatState extends State<_Stat> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  // Pulso 1 → 1.18 → 1: crece de golpe y vuelve, como un "latido".
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.18).chain(
        CurveTween(curve: Curves.easeOut),
      ),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.18, end: 1.0).chain(
        CurveTween(curve: Curves.easeIn),
      ),
      weight: 60,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(_Stat old) {
    super.didUpdateWidget(old);
    // Solo celebramos cuando el valor SUBE (no al cargar/reiniciar).
    if (widget.value > old.value && !_reducedMotion) {
      _pop.forward(from: 0);
    }
  }

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // El icono gana un halo de su color durante el "pop".
              AnimatedBuilder(
                animation: _pop,
                builder: (context, child) {
                  final t = _pop.isAnimating ? _scale.value - 1.0 : 0.0;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: t > 0
                          ? [
                              BoxShadow(
                                color: widget.color
                                    .withValues(alpha: (t * 3).clamp(0, 0.7)),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : const [],
                    ),
                    child: child,
                  );
                },
                child: Icon(widget.icon, color: widget.color, size: 14),
              ),
              const SizedBox(width: 4),
              _AnimatedCount(
                value: widget.value,
                reducedMotion: _reducedMotion,
                suffix: widget.total == null ? '' : '/${widget.total}',
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Número que "cuenta" suavemente desde su valor anterior hasta el nuevo, con
/// un sufijo opcional (p. ej. "/36"). Con reduced-motion salta directo.
class _AnimatedCount extends StatelessWidget {
  final int value;
  final String suffix;
  final bool reducedMotion;

  const _AnimatedCount({
    required this.value,
    this.suffix = '',
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.0,
    );
    if (reducedMotion) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value.toDouble(), end: value.toDouble()),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}
