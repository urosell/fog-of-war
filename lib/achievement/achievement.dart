// Logros (medallas): hitos coleccionables que premian cómo juegas.
//
// Cada medalla es independiente: se desbloquea al alcanzar su umbral en UNA
// métrica del juego (celdas de niebla, POIs, % de ciudad, atalayas o colecciones
// completadas) y se queda desbloqueada para siempre. La idea es tener MUCHAS
// medallitas que el jugador quiera completar. Las medallas se agrupan por
// familia (la métrica que miden) solo para presentarlas ordenadas.
//
// A diferencia de las colecciones, las medallas NO son contenido editable desde
// la hoja: son un sistema de juego, así que se definen aquí en código. Sus
// textos (nombre de familia) salen de las traducciones (ver achievements_screen).

import 'package:flutter/material.dart';

/// La métrica que mide una familia de medallas. Cada una se resuelve a un número
/// "actual" que se compara con el umbral de la medalla.
enum AchievementMetric { cells, pois, cityPercent, watchtowers, collections }

/// Una medalla concreta: una métrica + el umbral que hay que alcanzar.
class Achievement {
  /// Identificador estable (lo que se guarda al desbloquearla). No cambiar.
  final String id;
  final AchievementMetric metric;

  /// Valor de la métrica a partir del cual la medalla se desbloquea. Para
  /// [AchievementMetric.cityPercent] es un porcentaje (1..100).
  final int threshold;

  const Achievement({
    required this.id,
    required this.metric,
    required this.threshold,
  });
}

/// Icono que representa cada familia (el "glifo" de la medalla).
IconData iconForMetric(AchievementMetric metric) => switch (metric) {
      AchievementMetric.cells => Icons.explore,
      AchievementMetric.pois => Icons.place,
      AchievementMetric.cityPercent => Icons.map,
      AchievementMetric.watchtowers => Icons.visibility,
      AchievementMetric.collections => Icons.collections_bookmark,
    };

/// Etiqueta corta de una medalla (lo que la distingue dentro de su familia): el
/// umbral, con el signo de % para las de ciudad.
String medalLabel(AchievementMetric metric, int threshold) =>
    metric == AchievementMetric.cityPercent ? '$threshold%' : '$threshold';

/// Color de la medalla según lo "alta" que sea dentro de su familia (de bronce
/// la primera a diamante la última). [fraction] es umbral / umbral máximo de la
/// familia, de 0 a 1. Da una escalada visual que premia las medallas difíciles.
Color medalColor(double fraction) {
  if (fraction >= 1.0) return const Color(0xFF8C9EFF); // diamante (índigo claro)
  if (fraction >= 0.7) return const Color(0xFF4DD0E1); // platino (cian)
  if (fraction >= 0.4) return const Color(0xFFFFC107); // oro
  if (fraction >= 0.15) return const Color(0xFFC0C7D0); // plata
  return const Color(0xFFCD7F32); // bronce
}

/// Orden en que se presentan las familias en la pantalla de Logros.
const List<AchievementMetric> kAchievementFamilies = [
  AchievementMetric.cells,
  AchievementMetric.pois,
  AchievementMetric.cityPercent,
  AchievementMetric.watchtowers,
  AchievementMetric.collections,
];

// Prefijo estable de los ids de cada familia (id = "<prefijo>_<umbral>").
String _idPrefix(AchievementMetric metric) => switch (metric) {
      AchievementMetric.cells => 'cells',
      AchievementMetric.pois => 'pois',
      AchievementMetric.cityPercent => 'city',
      AchievementMetric.watchtowers => 'tower',
      AchievementMetric.collections => 'collection',
    };

// Crea las medallas de una familia a partir de su lista de umbrales.
List<Achievement> _family(AchievementMetric metric, List<int> thresholds) => [
      for (final t in thresholds)
        Achievement(id: '${_idPrefix(metric)}_$t', metric: metric, threshold: t),
    ];

/// Todas las medallas del juego, agrupadas por familia y en orden de umbral.
/// Para ampliar una familia basta con sumar umbrales a su lista (los ids son
/// estables: añadir uno nuevo no afecta a los ya conseguidos).
final List<Achievement> kAchievements = [
  // Explorador — celdas de niebla desveladas. Escalera larga que crece rápido.
  ..._family(AchievementMetric.cells,
      [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000]),
  // Cazatesoros — POIs descubiertos. Sube más allá de los POIs actuales: las
  // medallas altas se irán pudiendo conforme crezca el contenido de la hoja.
  ..._family(AchievementMetric.pois, [1, 5, 10, 15, 20, 30, 40, 50, 75, 100]),
  // Cartógrafo — porcentaje de la ciudad desvelado. Muchas medallas para que
  // siempre haya una "siguiente" cerca: 1, 2, 5 y luego de 5 en 5 hasta el 100.
  // Ojo: el % de ciudad es minúsculo (la caja de Barcelona incluye mar/montaña,
  // ver city.dart), así que las altas son un reto enorme a propósito.
  ..._family(AchievementMetric.cityPercent, [
    1, 2, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, //
    55, 60, 65, 70, 75, 80, 85, 90, 95, 100,
  ]),
  // Vigía — atalayas activadas: una medalla por cada una (hay 5).
  ..._family(AchievementMetric.watchtowers, [1, 2, 3, 4, 5]),
  // Coleccionista — colecciones completadas: una por cada una (hay 7).
  ..._family(AchievementMetric.collections, [1, 2, 3, 4, 5, 6, 7]),
];

/// Umbral máximo de una familia (para situar cada medalla en la escala de
/// color). Se calcula una vez sobre [kAchievements].
final Map<AchievementMetric, int> _familyMax = () {
  final max = <AchievementMetric, int>{};
  for (final a in kAchievements) {
    final cur = max[a.metric] ?? 0;
    if (a.threshold > cur) max[a.metric] = a.threshold;
  }
  return max;
}();

/// Color de la medalla [a] según su rango dentro de la familia.
Color colorForAchievement(Achievement a) {
  final max = _familyMax[a.metric] ?? a.threshold;
  return medalColor(max == 0 ? 1 : a.threshold / max);
}
