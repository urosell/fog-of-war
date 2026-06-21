// Pantalla "Logros": la vitrina de medallas del jugador.
//
// Una rejilla de medallitas agrupadas por familia (Explorador, Cazatesoros,
// Cartógrafo, Vigía, Coleccionista). Cada medalla es un hito independiente: en
// color y con brillo si la has conseguido, apagada y con candado si aún no. La
// idea es coleccionarlas todas. Se abre desde el HUD y se redibuja sola al
// desbloquear una (escucha al AchievementController).

import 'dart:ui';

import 'package:flutter/material.dart';

import '../achievement/achievement.dart';
import '../achievement/achievement_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';

/// Velo oscuro semitransparente sobre el mapa, a juego con las demás pantallas.
const Color _kScrim = Color(0xC2161A21);

// --- Resolución de textos (compartida con el toast de main) ---

/// Nombre de la familia de medallas en el idioma actual.
String achievementFamilyName(AppLocalizations l, AchievementMetric metric) =>
    switch (metric) {
      AchievementMetric.cells => l.achExplorerName,
      AchievementMetric.pois => l.achTreasureName,
      AchievementMetric.cityPercent => l.achCartographerName,
      AchievementMetric.watchtowers => l.achLookoutName,
      AchievementMetric.collections => l.achCollectorName,
    };

/// Frase corta que explica qué premia la familia ("Desvela la niebla"...).
String achievementFamilyTagline(AppLocalizations l, AchievementMetric metric) =>
    switch (metric) {
      AchievementMetric.cells => l.achExplorerTagline,
      AchievementMetric.pois => l.achTreasureTagline,
      AchievementMetric.cityPercent => l.achCartographerTagline,
      AchievementMetric.watchtowers => l.achLookoutTagline,
      AchievementMetric.collections => l.achCollectorTagline,
    };

class AchievementsScreen extends StatelessWidget {
  final AchievementController controller;

  const AchievementsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _kScrim,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l.achievementsTitle),
      ),
      body: Stack(
        children: [
          // Mapa de fondo difuminado + velo oscuro.
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: _kScrim),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Resumen: cuántas medallas llevas del total.
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      l.achievementsUnlocked(
                          controller.unlockedCount, controller.totalCount),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final metric in kAchievementFamilies)
                    _FamilySection(metric: metric, controller: controller),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Una familia: cabecera (icono, nombre, progreso) + rejilla de sus medallas.
class _FamilySection extends StatelessWidget {
  final AchievementMetric metric;
  final AchievementController controller;

  const _FamilySection({required this.metric, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final medallas = controller.all.where((a) => a.metric == metric).toList()
      ..sort((a, b) => a.threshold.compareTo(b.threshold));
    final ganadas = medallas.where(controller.isUnlocked).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la familia.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconForMetric(metric),
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievementFamilyName(l, metric),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        achievementFamilyTagline(l, metric),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contador "ganadas / total" de la familia.
                Text(
                  '$ganadas/${medallas.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Rejilla de medallas.
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final a in medallas)
                _MedalBadge(
                  achievement: a,
                  earned: controller.isUnlocked(a),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// Una medalla: disco con su umbral en el centro. En color y con halo si está
// ganada; apagada y con candado si no.
class _MedalBadge extends StatelessWidget {
  final Achievement achievement;
  final bool earned;

  const _MedalBadge({required this.achievement, required this.earned});

  @override
  Widget build(BuildContext context) {
    final color = colorForAchievement(achievement);
    final label = medalLabel(achievement.metric, achievement.threshold);

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.45)!,
                      ],
                    )
                  : null,
              color: earned ? null : const Color(0xFF2A2F3A),
              border: Border.all(
                color: earned
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.10),
                width: 2,
              ),
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 12,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: earned
                  ? Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                      ),
                    )
                  : Icon(
                      Icons.lock_outline,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          // Etiqueta bajo la medalla (siempre visible, también si está bloqueada).
          Text(
            label,
            style: TextStyle(
              color: earned
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.40),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
