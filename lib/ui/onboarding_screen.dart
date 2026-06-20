// Introducción de bienvenida ("¿de qué va el juego?") que se muestra UNA sola
// vez, la primera vez que se abre la app (ver onboarding/onboarding_storage).
//
// Son varias páginas deslizables con el mismo lenguaje visual del HUD (cristal
// esmerilado sobre un fondo oscuro de niebla). Va ANTES de pedir el permiso de
// ubicación, para que se entienda por qué el juego necesita el GPS. Respeta
// reduced-motion (sin animaciones de entrada si el sistema las desactiva).

import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import 'hud.dart' show kHudAccent, kHudCoral;

// Ámbar del "tesoro": el mismo color de los POIs descubiertos en el mapa.
const Color _poiAmber = Color(0xFFFFB300);

/// Una página de la intro: icono, color de acento, título y cuerpo.
class _Page {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  const _Page({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Page> _pages(BuildContext context) {
    final l = context.l10n;
    return [
      _Page(
        icon: Icons.travel_explore,
        accent: kHudAccent,
        title: l.onboardingWelcomeTitle,
        body: l.onboardingWelcomeBody,
      ),
      _Page(
        icon: Icons.directions_walk,
        accent: kHudAccent,
        title: l.onboardingMoveTitle,
        body: l.onboardingMoveBody,
      ),
      _Page(
        icon: Icons.stars_rounded,
        accent: _poiAmber,
        title: l.onboardingDiscoverTitle,
        body: l.onboardingDiscoverBody,
      ),
      _Page(
        icon: Icons.emoji_events_rounded,
        accent: kHudCoral,
        title: l.onboardingCollectTitle,
        body: l.onboardingCollectBody,
      ),
    ];
  }

  void _finish() => Navigator.of(context).maybePop();

  void _next(int total) {
    if (_index >= total - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pages = _pages(context);
    final isLast = _index == pages.length - 1;
    final accent = pages[_index].accent;

    return Scaffold(
      body: Container(
        // Fondo oscuro "de niebla" con un tinte sutil del acento de la página.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.45),
            radius: 1.2,
            colors: [
              Color.alphaBlend(accent.withValues(alpha: 0.16),
                  const Color(0xFF161A22)),
              const Color(0xFF0C0E13),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // "Saltar" arriba a la derecha (oculto en la última página).
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    child: Text(
                      l.onboardingSkip,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _PageView(page: pages[i]),
                ),
              ),
              // Indicador de puntos.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? accent
                            : Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              // Botón principal: "Siguiente" o, en la última, "¡A explorar!".
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _PrimaryButton(
                  label: isLast ? l.onboardingStart : l.onboardingNext,
                  accent: accent,
                  onPressed: () => _next(pages.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Contenido de una página: disco con icono (halo del acento), título y cuerpo.
class _PageView extends StatelessWidget {
  final _Page page;

  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Disco de cristal con el icono y un halo del color de la página.
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.accent.withValues(alpha: 0.14),
              border: Border.all(
                color: page.accent.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.accent.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Botón principal de cristal teñido del acento de la página.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.30),
            accent.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                height: 56,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
