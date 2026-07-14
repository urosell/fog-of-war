// Sincronización del progreso con la nube (Supabase). LOCAL-FIRST:
//
// - El disco local sigue siendo la fuente de verdad del juego; sin sesión (o
//   sin red) todo funciona exactamente igual que siempre.
// - Al INICIAR SESIÓN se hace un sync completo: se baja lo remoto, se UNE con
//   lo local (el progreso solo crece: unión de celdas/ids, nunca se pierde
//   nada) y se sube el resultado.
// - Después, cada cambio local se sube con un debounce (pocas filas: solo los
//   tiles de niebla tocados y los ids nuevos). Si falla (sin cobertura), lo
//   pendiente se re-marca y se reintenta solo.
// - Los puntos NO se suben: se derivan en servidor (triggers → player_stats;
//   ver supabase/schema.sql). El anti-trampas de celdas/hora vive allí: si
//   una subida excede el presupuesto, el upsert entero se rechaza y este
//   cliente la reintenta sin fin (un tramposo queda congelado, no borrado).
//
// Ajustes (avatar/idioma/misión): al iniciar sesión manda lo REMOTO (es tu
// cuenta recuperada en este móvil); después, cada cambio local se sube.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../achievement/achievement_controller.dart';
import '../avatar/avatar.dart';
import '../avatar/avatar_controller.dart';
import '../fog/fog_codec.dart';
import '../fog/fog_controller.dart';
import '../fog/tile_math.dart';
import '../locale/locale_controller.dart';
import '../mission/mission_controller.dart';
import '../poi/poi_controller.dart';
import '../watchtower/watchtower_controller.dart';
import 'cloud_auth.dart';

/// Cuánto se agrupan los cambios locales antes de subirlos.
const Duration _pushDebounce = Duration(seconds: 20);

/// Cuánto se espera para reintentar tras un fallo (sin red, etc.).
const Duration _retryDelay = Duration(minutes: 2);

enum CloudSyncStatus { idle, syncing, error }

class CloudSync extends ChangeNotifier {
  final CloudAuth auth;
  final FogController fog;
  final PoiController poi;
  final WatchtowerController watchtowers;
  final AchievementController achievements;
  final AvatarController avatar;
  final LocaleController locale;
  final MissionController mission;

  CloudSync({
    required this.auth,
    required this.fog,
    required this.poi,
    required this.watchtowers,
    required this.achievements,
    required this.avatar,
    required this.locale,
    required this.mission,
  });

  CloudSyncStatus _status = CloudSyncStatus.idle;
  CloudSyncStatus get status => _status;

  /// Última sincronización completada con éxito (para mostrar en Ajustes).
  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  // ¿Se hizo ya el sync completo de esta sesión? Hasta entonces no se hacen
  // pushes incrementales (el merge inicial debe ir primero).
  bool _fullSyncDone = false;
  bool _busy = false;

  Timer? _pushTimer;
  Timer? _retryTimer;

  // IDs que ya están en remoto (para subir solo los nuevos).
  final Set<String> _pushedPois = <String>{};
  final Set<String> _pushedTowers = <String>{};
  final Set<String> _pushedAchievements = <String>{};
  // Última foto de ajustes subida (para no subir si no cambió).
  (int, int, String?, String?)? _pushedSettings;

  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  bool get _active => auth.isAvailable && auth.isSignedIn;

  /// Engancha los listeners. Llamar una vez tras crear los controladores.
  void start() {
    if (!auth.isAvailable) return;
    auth.addListener(_onAuthChanged);
    fog.addListener(_schedulePush);
    poi.addListener(_schedulePush);
    watchtowers.addListener(_schedulePush);
    achievements.addListener(_schedulePush);
    avatar.addListener(_schedulePush);
    locale.addListener(_schedulePush);
    mission.addListener(_schedulePush);
    _onAuthChanged(); // por si ya había sesión guardada de otro arranque
  }

  void _onAuthChanged() {
    if (_active && !_fullSyncDone) {
      _fullSync();
    } else if (!_active && _fullSyncDone) {
      // Sesión cerrada: dejar de subir y olvidar el estado remoto conocido.
      _fullSyncDone = false;
      _pushedPois.clear();
      _pushedTowers.clear();
      _pushedAchievements.clear();
      _pushedSettings = null;
      _setStatus(CloudSyncStatus.idle);
    }
  }

  void _setStatus(CloudSyncStatus s) {
    if (s == _status) return;
    _status = s;
    notifyListeners();
  }

  void _schedulePush() {
    if (!_active || !_fullSyncDone) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDebounce, () => _pushNow());
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (!_active) return;
      _fullSyncDone ? _pushNow() : _fullSync();
    });
  }

  /// Sube ya lo pendiente (llamar al minimizar la app, junto al flush de la
  /// niebla, para no perder lo último si Android mata el proceso).
  Future<void> flush() async {
    _pushTimer?.cancel();
    if (_active && _fullSyncDone) await _pushNow();
  }

  // --- Sync completo al iniciar sesión: bajar, unir y subir todo ---

  Future<void> _fullSync() async {
    if (_busy || !_active) return;
    _busy = true;
    _setStatus(CloudSyncStatus.syncing);
    try {
      final uid = _uid!;

      // Niebla: bajar todos los tiles, unir con lo local y marcar TODO para
      // subir (la unión puede tener más celdas que el remoto en cualquier
      // tile; con cientos de tiles son unos pocos cientos de KB, una vez).
      final tileRows = await _db
          .from('fog_tiles')
          .select('x, y, bitmap')
          .eq('user_id', uid);
      final remoteCells = <CellId>{};
      for (final row in tileRows) {
        remoteCells.addAll(decodeTileBitmap(
          TileId(row['x'] as int, row['y'] as int),
          base64Decode(row['bitmap'] as String),
        ));
      }
      fog.mergeRemoteCells(remoteCells);
      fog.markAllTilesDirty();

      // Conjuntos de IDs: bajar, unir, y apuntar qué hay ya en remoto.
      _pushedPois
        ..clear()
        ..addAll(await _pullIds('discovered_pois', 'poi_id', uid));
      poi.mergeDiscovered(_pushedPois);

      _pushedTowers
        ..clear()
        ..addAll(await _pullIds('watchtowers_activated', 'watchtower_id', uid));
      watchtowers.mergeActivated(_pushedTowers);

      _pushedAchievements
        ..clear()
        ..addAll(await _pullIds('achievements_unlocked', 'achievement_id', uid));
      achievements.mergeUnlocked(_pushedAchievements);

      // Ajustes: si la cuenta ya tiene, mandan sobre lo local de este móvil.
      final settings = await _db
          .from('user_settings')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (settings != null) {
        // clamp: por si el catálogo de iconos/colores encogió entre versiones.
        avatar.setIcon((settings['avatar_icon'] as int? ?? avatar.iconIndex)
            .clamp(0, kAvatarIcons.length - 1));
        avatar.setColor((settings['avatar_color'] as int? ?? avatar.colorIndex)
            .clamp(0, kAvatarColors.length - 1));
        final code = settings['locale'] as String?;
        locale.setLocale(code == null ? null : Locale(code));
        mission.setMission(settings['mission_id'] as String?);
        _pushedSettings = (
          avatar.iconIndex,
          avatar.colorIndex,
          locale.locale?.languageCode,
          mission.selectedId,
        );
      }

      _fullSyncDone = true;
      await _pushNow(); // sube la unión (y los ajustes si aquí no había)
    } catch (e) {
      debugPrint('[cloud] sync completo falló (se reintentará): $e');
      _setStatus(CloudSyncStatus.error);
      _scheduleRetry();
    } finally {
      _busy = false;
    }
  }

  Future<Set<String>> _pullIds(String table, String column, String uid) async {
    final rows = await _db.from(table).select(column).eq('user_id', uid);
    return {for (final r in rows) r[column] as String};
  }

  // --- Push incremental: solo lo que cambió desde el último push ---

  bool _pushing = false;

  Future<void> _pushNow() async {
    if (_pushing || !_active || !_fullSyncDone) return;
    _pushing = true;
    _setStatus(CloudSyncStatus.syncing);
    final uid = _uid!;

    // Niebla: los tiles tocados se drenan; si la subida falla, se devuelven.
    final tiles = fog.takeDirtyTiles();
    try {
      if (tiles.isNotEmpty) {
        await _db.from('fog_tiles').upsert([
          for (final t in tiles)
            {
              'user_id': uid,
              'x': t.x,
              'y': t.y,
              'bitmap': base64Encode(fog.bitmapForTile(t)),
            },
        ]);
      }

      await _pushNewIds('discovered_pois', 'poi_id', uid,
          poi.discoveredIds, _pushedPois);
      await _pushNewIds('watchtowers_activated', 'watchtower_id', uid,
          watchtowers.activatedIds, _pushedTowers);
      await _pushNewIds('achievements_unlocked', 'achievement_id', uid,
          achievements.unlockedIds, _pushedAchievements);

      // Ajustes: una fila por usuario, solo si cambió desde el último push.
      final current = (
        avatar.iconIndex,
        avatar.colorIndex,
        locale.locale?.languageCode,
        mission.selectedId,
      );
      if (current != _pushedSettings) {
        await _db.from('user_settings').upsert({
          'user_id': uid,
          'avatar_icon': current.$1,
          'avatar_color': current.$2,
          'locale': current.$3,
          'mission_id': current.$4,
        });
        _pushedSettings = current;
      }

      _lastSyncAt = DateTime.now();
      _setStatus(CloudSyncStatus.idle);
      notifyListeners(); // lastSyncAt cambió aunque status siga idle
    } catch (e) {
      debugPrint('[cloud] subida falló (se reintentará): $e');
      fog.markTilesDirty(tiles); // que no se pierdan para el reintento
      _setStatus(CloudSyncStatus.error);
      _scheduleRetry();
    } finally {
      _pushing = false;
    }
  }

  // Inserta en [table] los ids de [current] que aún no estén en [pushed].
  // ignoreDuplicates: si otro móvil con la misma cuenta lo subió antes, la
  // fila existente (y su fecha) se queda como está.
  Future<void> _pushNewIds(String table, String column, String uid,
      Set<String> current, Set<String> pushed) async {
    final nuevos = current.difference(pushed);
    if (nuevos.isEmpty) return;
    await _db.from(table).upsert(
      [
        for (final id in nuevos) {'user_id': uid, column: id},
      ],
      ignoreDuplicates: true,
    );
    pushed.addAll(nuevos);
  }

  @override
  void dispose() {
    _pushTimer?.cancel();
    _retryTimer?.cancel();
    if (auth.isAvailable) {
      auth.removeListener(_onAuthChanged);
      fog.removeListener(_schedulePush);
      poi.removeListener(_schedulePush);
      watchtowers.removeListener(_schedulePush);
      achievements.removeListener(_schedulePush);
      avatar.removeListener(_schedulePush);
      locale.removeListener(_schedulePush);
      mission.removeListener(_schedulePush);
    }
    super.dispose();
  }
}
