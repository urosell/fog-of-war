// Clasificación (ranking) de jugadores: global y por colección temática de POIs.
//
// IMPORTANTE: hoy NO hay backend ni cuentas, así que los rivales son SIMULADOS
// (`kRivals`, lista fija escrita a mano). Cada rival se describe igual que un
// jugador real: cuántas celdas de niebla ha descubierto y QUÉ POIs tiene. De ese
// mismo dato salen los dos rankings:
//   - GLOBAL: por puntuación (celdas * kPointsPerCell + puntos de sus POIs).
//   - POR COLECCIÓN: por cuántos POIs de esa colección lleva descubiertos.
// Cuando exista Supabase, basta sustituir `kRivals` por los jugadores reales:
// la lógica de ordenación (`buildLeaderboard`) y la interfaz no cambian.

import '../poi/poi.dart';

/// Cuántos puntos vale cada celda de niebla descubierta. La puntuación total de
/// un jugador es `celdas * kPointsPerCell + puntos de POIs`. Subir este número
/// premia más la exploración; bajarlo da más peso a visitar POIs.
const int kPointsPerCell = 1;

/// Puntuación total a partir de celdas de niebla y puntos de POIs. Función pura.
int totalScore({required int cells, required int poiPoints}) {
  return cells * kPointsPerCell + poiPoints;
}

/// Puntos de cada POI indexados por su id (derivado del pozo `kBarcelonaPois`).
/// Sirve para sumar la puntuación de POIs de un rival a partir de sus ids.
final Map<String, int> kPoiPointsById = {
  for (final p in kBarcelonaPois) p.id: p.points,
};

/// Un jugador genérico con un nombre y una puntuación ya calculada. Es lo que
/// ordena `buildLeaderboard`, sea cual sea el criterio (global o por colección).
class Player {
  final String name;
  final int score;

  const Player({required this.name, required this.score});
}

/// Un jugador ya colocado en la tabla: con su puesto (rank, 1 = primero) y una
/// marca [isYou] para resaltarte en la interfaz.
class RankedPlayer {
  final int rank;
  final String name;
  final int score;
  final bool isYou;

  const RankedPlayer({
    required this.rank,
    required this.name,
    required this.score,
    required this.isYou,
  });
}

/// Resultado de construir una clasificación: el [top] (los N primeros) y [you]
/// (tu fila con tu puesto, aunque quedes fuera del top, para mostrarla aparte).
class Leaderboard {
  final List<RankedPlayer> top;
  final RankedPlayer you;

  const Leaderboard({required this.top, required this.you});

  /// True si tu fila ya aparece dentro del [top] (no hace falta repetirla).
  bool get youInTop => you.rank <= top.length;
}

// Entrada interna mientras ordenamos (antes de asignar el puesto).
class _Entry {
  final String name;
  final int score;
  final bool isYou;
  const _Entry(this.name, this.score, this.isYou);
}

/// Construye una clasificación mezclando a [rivals] con tu puntuación [yourScore]
/// y ordenando de mayor a menor. Devuelve el top [topCount] y tu fila.
///
/// Desempate: tú quedas por delante (es tu app) y, entre rivales empatados, por
/// orden alfabético (determinista).
Leaderboard buildLeaderboard({
  required int yourScore,
  required List<Player> rivals,
  String yourName = 'Tú',
  int topCount = 10,
}) {
  final entries = <_Entry>[
    for (final r in rivals) _Entry(r.name, r.score, false),
    _Entry(yourName, yourScore, true),
  ];

  entries.sort((a, b) {
    final byScore = b.score.compareTo(a.score); // mayor puntuación primero
    if (byScore != 0) return byScore;
    if (a.isYou != b.isYou) return a.isYou ? -1 : 1; // tú ganas el empate
    return a.name.compareTo(b.name); // resto, alfabético (determinista)
  });

  final ranked = <RankedPlayer>[
    for (var i = 0; i < entries.length; i++)
      RankedPlayer(
        rank: i + 1,
        name: entries[i].name,
        score: entries[i].score,
        isYou: entries[i].isYou,
      ),
  ];

  return Leaderboard(
    top: ranked.take(topCount).toList(),
    you: ranked.firstWhere((p) => p.isYou),
  );
}

/// Un rival SIMULADO, descrito como un jugador real: sus celdas de niebla y el
/// conjunto de POIs que ha descubierto (por id).
class Rival {
  final String name;
  final int cells;
  final Set<String> poiIds;

  const Rival({required this.name, required this.cells, required this.poiIds});

  /// Suma de puntos de los POIs que ha descubierto.
  int get poiPoints {
    var s = 0;
    for (final id in poiIds) {
      s += kPoiPointsById[id] ?? 0;
    }
    return s;
  }

  /// Puntuación global (la misma fórmula que la tuya).
  int get globalScore => totalScore(cells: cells, poiPoints: poiPoints);

  /// Cuántos POIs de [collectionPoiIds] ha descubierto este rival.
  int discoveredIn(Iterable<String> collectionPoiIds) {
    var n = 0;
    for (final id in collectionPoiIds) {
      if (poiIds.contains(id)) n++;
    }
    return n;
  }
}

/// Rivales proyectados como jugadores para el ranking GLOBAL (por puntuación).
List<Player> rivalsForGlobal() => [
      for (final r in kRivals) Player(name: r.name, score: r.globalScore),
    ];

/// Rivales proyectados para el ranking de UNA colección: su puntuación es el
/// número de POIs de [collectionPoiIds] que han descubierto.
List<Player> rivalsForCollection(List<String> collectionPoiIds) => [
      for (final r in kRivals)
        Player(name: r.name, score: r.discoveredIn(collectionPoiIds)),
    ];

/// Rivales SIMULADOS de Barcelona (provisional, hasta tener backend real).
/// Cada uno tiene un perfil distinto (un experto en Gaudí, un explorador puro,
/// un fan otaku...) para que los rankings por colección tengan líderes propios.
/// Para ajustar la dificultad: cambiar `cells` o el conjunto de `poiIds`.
const List<Rival> kRivals = [
  Rival(
    name: 'NieblaKiller', // explorador total: muchísima niebla y POIs
    cells: 4600,
    poiIds: {
      'sagrada_familia', 'park_guell', 'casa_batllo', 'la_pedrera',
      'catedral_bcn', 'mnac', 'castell_montjuic', 'parc_ciutadella',
      'tibidabo', 'casa_vicens', 'mirador_colom', 'bunkers_carmel',
    },
  ),
  Rival(
    name: 'GaudíHunter', // especialista: completa la Ruta Gaudí entera
    cells: 3500,
    poiIds: {
      'sagrada_familia', 'casa_batllo', 'la_pedrera', 'park_guell',
      'casa_vicens', 'palau_guell', 'torre_bellesguard',
    },
  ),
  Rival(
    name: 'EixampleWalker',
    cells: 3700,
    poiIds: {
      'sagrada_familia', 'casa_batllo', 'la_pedrera', 'casa_vicens',
      'park_guell', 'placa_catalunya', 'arc_triomf', 'museu_picasso',
    },
  ),
  Rival(
    name: 'La Rambla Roja',
    cells: 3000,
    poiIds: {
      'placa_catalunya', 'mirador_colom', 'museu_picasso', 'catedral_bcn',
      'parc_ciutadella',
    },
  ),
  Rival(
    name: 'MontjuïcMax',
    cells: 2600,
    poiIds: {
      'castell_montjuic', 'mnac', 'mirador_colom', 'tibidabo', 'bunkers_carmel',
    },
  ),
  Rival(
    name: 'BarriGòtic',
    cells: 2200,
    poiIds: {
      'catedral_bcn', 'placa_catalunya', 'museu_picasso', 'sagrada_familia',
      'gigamesh',
    },
  ),
  Rival(
    name: 'Tibidabo Tina',
    cells: 1800,
    poiIds: {'tibidabo', 'bunkers_carmel', 'mirador_colom'},
  ),
  Rival(
    name: 'GràciaGo',
    cells: 1450,
    poiIds: {'casa_vicens', 'park_guell', 'palau_guell'},
  ),
  Rival(
    name: 'PoblenouPau',
    cells: 1100,
    poiIds: {'parc_ciutadella', 'arc_triomf'},
  ),
  Rival(
    name: 'MangaKaijuu', // fan otaku: tiene las dos tiendas de cómics
    cells: 900,
    poiIds: {'norma_comics', 'gigamesh', 'placa_catalunya'},
  ),
  Rival(
    name: 'SagradaSam',
    cells: 800,
    poiIds: {'sagrada_familia'},
  ),
  Rival(
    name: 'TuristaPerdido',
    cells: 200,
    poiIds: {'placa_catalunya'},
  ),
];
