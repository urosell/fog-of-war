import 'package:flutter_test/flutter_test.dart';
import 'package:fog_of_war/poi/poi.dart';
import 'package:fog_of_war/poi/poi_collection.dart';
import 'package:fog_of_war/ranking/ranking.dart';

void main() {
  group('totalScore', () {
    test('suma celdas (x kPointsPerCell) y puntos de POIs', () {
      expect(
        totalScore(cells: 100, poiPoints: 45),
        100 * kPointsPerCell + 45,
      );
    });

    test('sin nada es 0', () {
      expect(totalScore(cells: 0, poiPoints: 0), 0);
    });
  });

  group('buildLeaderboard', () {
    // Rivales de prueba pequeños y deterministas.
    const rivals = [
      Player(name: 'Ana', score: 300),
      Player(name: 'Beto', score: 200),
      Player(name: 'Caro', score: 100),
    ];

    test('te coloca según tu puntuación y asigna puestos 1..N', () {
      final board = buildLeaderboard(yourScore: 250, rivals: rivals);
      // Orden esperado: Ana 300, Tú 250, Beto 200, Caro 100.
      expect(board.top.map((p) => p.name).toList(),
          ['Ana', 'Tú', 'Beto', 'Caro']);
      expect(board.top.map((p) => p.rank).toList(), [1, 2, 3, 4]);
      expect(board.you.rank, 2);
      expect(board.you.isYou, isTrue);
      expect(board.youInTop, isTrue);
    });

    test('en empate, tú quedas por delante del rival', () {
      final board = buildLeaderboard(yourScore: 200, rivals: rivals);
      final nombres = board.top.map((p) => p.name).toList();
      expect(nombres.indexOf('Tú'), lessThan(nombres.indexOf('Beto')));
      expect(board.you.rank, 2);
    });

    test('respeta topCount y te deja fuera si no llegas', () {
      final board =
          buildLeaderboard(yourScore: 50, rivals: rivals, topCount: 2);
      expect(board.top.length, 2);
      expect(board.top.map((p) => p.name).toList(), ['Ana', 'Beto']);
      expect(board.you.rank, 4);
      expect(board.youInTop, isFalse);
    });

    test('solo eres tú: quedas primero', () {
      final board = buildLeaderboard(yourScore: 10, rivals: []);
      expect(board.top.single.name, 'Tú');
      expect(board.you.rank, 1);
    });

    test('marca isYou solo en tu fila', () {
      final board = buildLeaderboard(yourScore: 250, rivals: rivals);
      expect(board.top.where((p) => p.isYou).length, 1);
    });
  });

  group('Rival', () {
    const r = Rival(
      name: 'Test',
      cells: 100,
      poiIds: {'sagrada_familia', 'park_guell'}, // iglesia 45 + parque 30
    );

    test('poiPoints suma los puntos de sus POIs', () {
      expect(r.poiPoints, 45 + 30);
    });

    test('globalScore = celdas + puntos de POIs', () {
      expect(r.globalScore, 100 * kPointsPerCell + 75);
    });

    test('discoveredIn cuenta solo los POIs de la colección que tiene', () {
      expect(r.discoveredIn(['sagrada_familia', 'casa_batllo']), 1);
      expect(r.discoveredIn(['casa_batllo', 'mnac']), 0);
      expect(r.discoveredIn(['sagrada_familia', 'park_guell']), 2);
    });
  });

  group('Rivales simulados (kRivals)', () {
    test('todos sus POIs existen en el pozo kBarcelonaPois', () {
      final pozo = {for (final p in kBarcelonaPois) p.id};
      for (final r in kRivals) {
        for (final id in r.poiIds) {
          expect(pozo.contains(id), isTrue, reason: '$id de ${r.name}');
        }
      }
    });

    test('ranking global ordenable: Top 10 + tú', () {
      final board =
          buildLeaderboard(yourScore: 1000, rivals: rivalsForGlobal());
      expect(board.top.length, 10);
      expect(board.you.isYou, isTrue);
    });

    test('ranking por colección puntúa por POIs descubiertos de la colección',
        () {
      final gaudi = kPoiCollections.firstWhere((c) => c.id == 'gaudi');
      final players = rivalsForCollection(gaudi.poiIds);
      // GaudíHunter completa la Ruta Gaudí entera.
      final hunter = players.firstWhere((p) => p.name == 'GaudíHunter');
      expect(hunter.score, gaudi.poiIds.length);
      // Y lidera ese ranking.
      final board = buildLeaderboard(yourScore: 0, rivals: players);
      expect(board.top.first.name, 'GaudíHunter');
    });
  });
}
