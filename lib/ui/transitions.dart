// Transiciones de navegación compartidas por la app.
//
// appRoute() construye una ruta que hace entrar la pantalla nueva deslizándose
// desde abajo con un fundido (como un panel que aparece). Se usa al abrir
// Ajustes, Clasificación y Colecciones para una sensación coherente y cuidada.

import 'package:flutter/material.dart';

/// Ruta con transición "deslizar desde abajo + fundido".
PageRoute<T> appRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Curva suave de desaceleración al entrar.
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      // Sube desde un 8% por debajo hasta su sitio.
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
