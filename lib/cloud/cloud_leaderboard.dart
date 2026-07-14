// Lectura del leaderboard REAL desde Supabase (RPCs de supabase/schema.sql).
//
// El servidor solo guarda datos crudos (celdas contadas por triggers, ids de
// POIs); el CONTENIDO (puntos por POI, colecciones) vive en el cliente, así
// que cada llamada manda su catálogo como parámetro y el servidor puntúa y
// ordena con él. Las RPCs devuelven el top N + siempre tu fila (is_you).
//
// Sin sesión (o si la llamada falla) se devuelve null y la pantalla de
// ranking cae a los rivales simulados de siempre (ranking.dart): la nube
// nunca es imprescindible, como en el resto de la app.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ranking/ranking.dart';
import 'cloud_auth.dart';

/// Cuánto vale una respuesta cacheada: evita machacar el backend si el
/// jugador entra y sale del ranking varias veces seguidas.
const Duration _cacheTtl = Duration(seconds: 45);

class CloudLeaderboard {
  final CloudAuth auth;

  CloudLeaderboard({required this.auth});

  /// ¿Tiene sentido pedir el ranking real? (backend operativo + sesión).
  bool get isActive => auth.isAvailable && auth.isSignedIn;

  // Última respuesta por ranking ("global" o "col:<id>"), con su hora.
  final Map<String, (DateTime, List<RemoteRank>)> _cache = {};

  /// Ranking global: celdas * [cellPoints] + puntos de POIs descubiertos
  /// según [poiPoints] (id → puntos, el catálogo vivo del cliente).
  /// null = sin nube o fallo de red (el llamante decide el plan B).
  Future<List<RemoteRank>?> global({
    required int cellPoints,
    required Map<String, int> poiPoints,
    int topCount = 10,
    bool force = false,
  }) {
    return _fetch('global', force, 'global_leaderboard', {
      'cell_points': cellPoints,
      'poi_points': poiPoints,
      'top_count': topCount,
    });
  }

  /// Ranking de una colección: nº de POIs de [poiIds] descubiertos.
  Future<List<RemoteRank>?> collection({
    required String collectionId,
    required List<String> poiIds,
    int topCount = 10,
    bool force = false,
  }) {
    return _fetch('col:$collectionId', force, 'collection_leaderboard', {
      'poi_ids': poiIds,
      'top_count': topCount,
    });
  }

  Future<List<RemoteRank>?> _fetch(String key, bool force, String fn,
      Map<String, dynamic> params) async {
    if (!isActive) return null;
    final hit = _cache[key];
    if (!force &&
        hit != null &&
        DateTime.now().difference(hit.$1) < _cacheTtl) {
      return hit.$2;
    }
    try {
      final rows =
          await Supabase.instance.client.rpc(fn, params: params) as List;
      final parsed = [
        for (final r in rows.cast<Map<String, dynamic>>())
          RemoteRank(
            rank: (r['rank'] as num).toInt(),
            name: r['display_name'] as String? ?? 'Explorador',
            score: (r['score'] as num).toInt(),
            isYou: r['is_you'] as bool? ?? false,
          ),
      ];
      _cache[key] = (DateTime.now(), parsed);
      return parsed;
    } catch (e) {
      debugPrint('[cloud] leaderboard falló (se usará el simulado): $e');
      return null;
    }
  }
}
