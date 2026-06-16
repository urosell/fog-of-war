// Aviso flotante estilo juego ("toast") para celebrar logros: descubrir un POI,
// avistar una zona desde una atalaya, etc.
//
// Es una tarjeta de cristal esmerilado (a juego con el HUD) que entra deslizando
// desde arriba con un fundido y un leve "zoom", se queda un par de segundos y
// se va sola. Sustituye al SnackBar plano para que el feedback se sienta de
// videojuego. Respeta reduced-motion (sin deslizamiento/zoom, solo fundido).

import 'dart:ui';

import 'package:flutter/material.dart';

/// Muestra un toast de juego en la parte superior. [accent] tiñe el icono y su
/// halo; [icon] es el icono que lo encabeza; [message] el texto (una línea o
/// dos). Si ya hay uno visible, lo reemplaza.
void showGameToast(
  BuildContext context, {
  required IconData icon,
  required Color accent,
  required String message,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  // Cierra el toast anterior (si lo hay) para no apilarlos.
  _current?.remove();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _GameToastCard(
      icon: icon,
      accent: accent,
      message: message,
      onDismissed: () {
        if (_current == entry) _current = null;
        entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

// Toast actualmente en pantalla (para reemplazarlo si llega otro).
OverlayEntry? _current;

class _GameToastCard extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String message;
  final VoidCallback onDismissed;

  const _GameToastCard({
    required this.icon,
    required this.accent,
    required this.message,
    required this.onDismissed,
  });

  @override
  State<_GameToastCard> createState() => _GameToastCardState();
}

class _GameToastCardState extends State<_GameToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 240),
  );

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  // Entra subiendo desde abajo (va anclado a la parte inferior).
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.6),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  ));
  late final Animation<double> _scale = Tween<double>(
    begin: 0.9,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _c.forward();
    // Tras un par de segundos, se va solo.
    Future.delayed(const Duration(milliseconds: 2400), () async {
      if (!mounted) return;
      await _c.reverse();
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final media = MediaQuery.of(context);

    Widget card = _buildCard(context);
    // Con reduced-motion: solo fundido (sin deslizar ni escalar).
    card = reduced
        ? FadeTransition(opacity: _fade, child: card)
        : FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(scale: _scale, child: card),
            ),
          );

    // Abajo-centro, por encima de los botones de las esquinas inferiores.
    return Positioned(
      bottom: media.padding.bottom + 88,
      left: 0,
      right: 0,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: card,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(20));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.black.withValues(alpha: 0.38),
            Colors.black.withValues(alpha: 0.50),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: widget.accent.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          // Halo del color de acento (le da el toque de "logro").
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Disco con el icono y un halo a juego.
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accent.withValues(alpha: 0.22),
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      // Sin esto, el texto en un Overlay (sin ancestro Material)
                      // sale con el subrayado amarillo de depuración.
                      decoration: TextDecoration.none,
                    ),
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
