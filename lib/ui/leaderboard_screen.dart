// Pantallas de clasificación (ranking): la GLOBAL (por puntuación) y la de UNA
// colección temática (por POIs descubiertos de esa colección).
//
// Ambas comparten la misma vista (`_LeaderboardView`): cabecera con tu puesto,
// podio con medallas oro/plata/bronce, tu fila resaltada y, si quedas fuera del
// top, tu fila aparte al final. Solo cambian los datos y los textos.
//
// Tu puntuación se calcula EN VIVO (ListenableBuilder) a partir de tu progreso
// real; los rivales son simulados (ver ranking.dart) hasta tener backend.

import 'package:flutter/material.dart';

import '../fog/fog_controller.dart';
import '../l10n/l10n_ext.dart';
import '../poi/poi_collection.dart';
import '../poi/poi_controller.dart';
import '../ranking/ranking.dart';
import 'hud.dart' show kHudAccent;

/// Fondo oscuro, en sintonía con el resto de pantallas y la niebla.
const Color _kBackground = Color(0xFF161A21);

/// Clasificación GLOBAL: ordena por puntuación (celdas + puntos de POIs).
class LeaderboardScreen extends StatelessWidget {
  final FogController fogController;
  final PoiController poiController;

  const LeaderboardScreen({
    super.key,
    required this.fogController,
    required this.poiController,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _LeaderboardScaffold(
      title: l.leaderboardTitle,
      accent: kHudAccent,
      listenable: Listenable.merge([fogController, poiController]),
      buildBoard: () {
        final yourScore = totalScore(
          cells: fogController.discoveredCount,
          poiPoints: poiController.totalPoints,
        );
        final board = buildLeaderboard(
          yourScore: yourScore,
          rivals: rivalsForGlobal(),
        );
        return _BoardData(
          board: board,
          headline: l.rankHeadline(board.you.rank),
          subtitle: l.globalSubtitle(board.you.score),
          valueText: (score) => '$score',
          unit: l.unitPts,
        );
      },
    );
  }
}

/// Clasificación de UNA colección: ordena por nº de POIs de la colección
/// descubiertos (carrera por completar la "Ruta Gaudí", etc.).
class CollectionLeaderboardScreen extends StatelessWidget {
  final PoiController poiController;
  final PoiCollection collection;

  const CollectionLeaderboardScreen({
    super.key,
    required this.poiController,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = collection.poiIds.length;
    return _LeaderboardScaffold(
      title: collection
          .localizedName(Localizations.localeOf(context).languageCode),
      accent: collection.accent,
      listenable: poiController,
      buildBoard: () {
        final yours = collection.discoveredCount(poiController.isDiscoveredId);
        final board = buildLeaderboard(
          yourScore: yours,
          rivals: rivalsForCollection(collection.poiIds),
        );
        return _BoardData(
          board: board,
          headline: l.rankHeadline(board.you.rank),
          subtitle: l.collectionSubtitle(board.you.score, total),
          valueText: (score) => '$score/$total',
          unit: l.unitPois,
        );
      },
    );
  }
}

// Datos ya listos para pintar una clasificación (board + textos).
class _BoardData {
  final Leaderboard board;
  final String headline;
  final String subtitle;
  final String Function(int score) valueText;
  final String unit;

  const _BoardData({
    required this.board,
    required this.headline,
    required this.subtitle,
    required this.valueText,
    required this.unit,
  });
}

// Andamiaje común: Scaffold + AppBar + recálculo en vivo de la clasificación.
class _LeaderboardScaffold extends StatelessWidget {
  final String title;
  final Color accent;
  final Listenable listenable;
  final _BoardData Function() buildBoard;

  const _LeaderboardScaffold({
    required this.title,
    required this.accent,
    required this.listenable,
    required this.buildBoard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title),
      ),
      body: ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => _LeaderboardView(data: buildBoard(), accent: accent),
      ),
    );
  }
}

// La lista en sí: cabecera + filas del top + (si procede) tu fila aparte.
class _LeaderboardView extends StatelessWidget {
  final _BoardData data;
  final Color accent;

  const _LeaderboardView({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final board = data.board;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Header(
          headline: data.headline,
          subtitle: data.subtitle,
          accent: accent,
        ),
        const SizedBox(height: 16),
        for (final p in board.top)
          _RankRow(
            player: p,
            valueText: data.valueText(p.score),
            unit: data.unit,
            accent: accent,
          ),
        // Si quedas fuera del top, te enseñamos tu fila aparte.
        if (!board.youInTop) ...[
          const _Divider(),
          _RankRow(
            player: board.you,
            valueText: data.valueText(board.you.score),
            unit: data.unit,
            accent: accent,
          ),
        ],
      ],
    );
  }
}

// Cabecera: trofeo + tu puesto y un resumen de tu puntuación/progreso.
class _Header extends StatelessWidget {
  final String headline;
  final String subtitle;
  final Color accent;

  const _Header({
    required this.headline,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: accent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Una fila de la tabla: puesto + nombre + valor. Resalta si eres tú.
class _RankRow extends StatelessWidget {
  final RankedPlayer player;
  final String valueText;
  final String unit;
  final Color accent;

  const _RankRow({
    required this.player,
    required this.valueText,
    required this.unit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final you = player.isYou;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: you
            ? accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: you
              ? accent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: player.rank),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              you ? context.l10n.youSuffix(player.name) : player.name,
              style: TextStyle(
                color: you ? accent : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              color: you ? accent : Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Insignia del puesto: medalla de color para el podio (1-3), número para el resto.
class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  static const Map<int, Color> _medal = {
    1: Color(0xFFFFD54F), // oro
    2: Color(0xFFB0BEC5), // plata
    3: Color(0xFFBCAAA4), // bronce
  };

  @override
  Widget build(BuildContext context) {
    final medalla = _medal[rank];
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (medalla ?? Colors.white)
            .withValues(alpha: medalla != null ? 0.20 : 0.06),
        shape: BoxShape.circle,
        border: medalla != null
            ? Border.all(color: medalla.withValues(alpha: 0.60))
            : null,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: medalla ?? Colors.white.withValues(alpha: 0.70),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Separador "···" entre el top y tu fila cuando quedas fuera del top.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          '· · ·',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
