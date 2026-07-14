// Pantallas de clasificación (ranking): la GLOBAL (por puntuación) y la de UNA
// colección temática (por POIs descubiertos de esa colección).
//
// Ambas comparten la misma vista (`_LeaderboardView`): cabecera con tu puesto,
// podio con medallas oro/plata/bronce, tu fila resaltada y, si quedas fuera del
// top, tu fila aparte al final. Solo cambian los datos y los textos.
//
// Fuente de datos: con sesión iniciada se pide el leaderboard REAL a la nube
// (cloud_leaderboard.dart), con arrastrar-para-refrescar; sin sesión (o si la
// petición falla) se cae a los rivales simulados de ranking.dart, calculados
// EN VIVO (ListenableBuilder) a partir de tu progreso real.

import 'package:flutter/material.dart';

import '../cloud/cloud_leaderboard.dart';
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
  // Obligatorio (aunque admite null) a propósito: que ningún llamante se
  // olvide de pasarlo y caiga al ranking simulado en silencio.
  final CloudLeaderboard? cloud;

  const LeaderboardScreen({
    super.key,
    required this.fogController,
    required this.poiController,
    required this.cloud,
  });

  // Tu puntuación según TU móvil (para el modo simulado y como plan B si el
  // servidor aún no tiene tu fila).
  int _localScore() => totalScore(
        cells: fogController.discoveredCount,
        poiPoints: poiController.totalPoints,
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nube = cloud;
    return _LeaderboardScaffold(
      title: l.leaderboardTitle,
      accent: kHudAccent,
      listenable: Listenable.merge([fogController, poiController]),
      fetchCloud: nube == null || !nube.isActive
          ? null
          : ({force = false}) async {
              final rows = await nube.global(
                cellPoints: kPointsPerCell,
                // El catálogo vivo (viene de la hoja de contenido): id → puntos.
                poiPoints: {
                  for (final p in poiController.allPois) p.id: p.points,
                },
                force: force,
              );
              if (rows == null) return null;
              return leaderboardFromRemote(rows,
                  fallbackYourScore: _localScore());
            },
      buildBoard: (remote) {
        final board = remote ??
            buildLeaderboard(
              yourScore: _localScore(),
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
  // Obligatorio (aunque admite null), igual que en LeaderboardScreen.
  final CloudLeaderboard? cloud;

  const CollectionLeaderboardScreen({
    super.key,
    required this.poiController,
    required this.collection,
    required this.cloud,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = collection.poiIds.length;
    final nube = cloud;
    return _LeaderboardScaffold(
      title: collection
          .localizedName(Localizations.localeOf(context).languageCode),
      accent: collection.accent,
      listenable: poiController,
      fetchCloud: nube == null || !nube.isActive
          ? null
          : ({force = false}) async {
              final rows = await nube.collection(
                collectionId: collection.id,
                poiIds: collection.poiIds,
                force: force,
              );
              if (rows == null) return null;
              return leaderboardFromRemote(rows,
                  fallbackYourScore: collection
                      .discoveredCount(poiController.isDiscoveredId));
            },
      buildBoard: (remote) {
        final board = remote ??
            buildLeaderboard(
              yourScore:
                  collection.discoveredCount(poiController.isDiscoveredId),
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

// Petición del leaderboard real: null = sin nube esta vez (usar el simulado).
// [force] salta la caché (para el gesto de refrescar).
typedef _FetchCloud = Future<Leaderboard?> Function({bool force});

// Andamiaje común: Scaffold + AppBar + recálculo en vivo de la clasificación.
// Con [fetchCloud] pide el ranking real al entrar (y al arrastrar hacia
// abajo); si devuelve null, [buildBoard] recibe null y pinta el simulado.
class _LeaderboardScaffold extends StatefulWidget {
  final String title;
  final Color accent;
  final Listenable listenable;
  final _FetchCloud? fetchCloud;
  final _BoardData Function(Leaderboard? remote) buildBoard;

  const _LeaderboardScaffold({
    required this.title,
    required this.accent,
    required this.listenable,
    required this.fetchCloud,
    required this.buildBoard,
  });

  @override
  State<_LeaderboardScaffold> createState() => _LeaderboardScaffoldState();
}

class _LeaderboardScaffoldState extends State<_LeaderboardScaffold> {
  // Último leaderboard real recibido (null = la petición falló → simulado).
  Leaderboard? _remote;
  // false hasta que termina la primera petición (mientras: spinner). Al
  // refrescar con el gesto NO se vuelve a false: la lista se queda a la vista.
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.fetchCloud != null) {
      _load();
    }
  }

  Future<void> _load({bool force = false}) async {
    final result = await widget.fetchCloud!(force: force);
    if (!mounted) return;
    setState(() {
      _remote = result;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title),
      ),
      body: ListenableBuilder(
        listenable: widget.listenable,
        builder: (context, _) {
          if (widget.fetchCloud == null) {
            // Sin nube: el simulado de siempre, recalculado en vivo.
            return _LeaderboardView(
                data: widget.buildBoard(null), accent: widget.accent);
          }
          if (!_loaded) {
            return Center(
                child: CircularProgressIndicator(color: widget.accent));
          }
          // _remote == null → la petición falló: plan B simulado.
          return RefreshIndicator(
            color: widget.accent,
            backgroundColor: _kBackground,
            onRefresh: () => _load(force: true),
            child: _LeaderboardView(
                data: widget.buildBoard(_remote), accent: widget.accent),
          );
        },
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
      // Siempre desplazable: sin esto, con pocas filas (leaderboard real
      // recién estrenado) el gesto de arrastrar-para-refrescar no funciona.
      physics: const AlwaysScrollableScrollPhysics(),
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
