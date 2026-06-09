// Piezas visuales del HUD (la interfaz que va flotando sobre el mapa).
//
// Todo el HUD usa un efecto de "cristal esmerilado" (frosted glass): se desenfoca
// lo que hay detrás (el mapa) y se le pone una capa oscura translúcida con un
// borde fino. Da un aspecto moderno y de videojuego, y deja entrever el mapa.

import 'dart:ui';

import 'package:flutter/material.dart';

/// Color de acento del HUD (un turquesa brillante que destaca sobre el mapa).
const Color kHudAccent = Color(0xFF4DE3C2);

/// Panel rectangular con esquinas redondeadas y efecto cristal esmerilado.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Botón redondo de cristal esmerilado con un icono.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final boton = ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.black.withValues(alpha: 0.38),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? boton : Tooltip(message: tooltip!, child: boton);
  }
}

/// Tarjeta de estadísticas: ciudad + % descubierto, celdas, puntos y POIs.
class HudStats extends StatelessWidget {
  final String cityName;
  final double percentage;
  final int cells;
  final int points;
  final int poisDiscovered;
  final int poisTotal;

  const HudStats({
    super.key,
    required this.cityName,
    required this.percentage,
    required this.cells,
    required this.points,
    required this.poisDiscovered,
    required this.poisTotal,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: kHudAccent, size: 20),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Stat(value: '${percentage.toStringAsFixed(2)}%', label: 'ciudad'),
                  _Stat(value: '$cells', label: 'celdas'),
                  _Stat(value: '$points', label: 'puntos'),
                  _Stat(value: '$poisDiscovered/$poisTotal', label: 'POIs'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un valor destacado con su etiqueta pequeña debajo (ej. "480" / "celdas").
class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: kHudAccent,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
