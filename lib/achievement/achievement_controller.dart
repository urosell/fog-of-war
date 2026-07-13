// Estado de los logros: cuáles has desbloqueado y cómo vas con el resto.
//
// Extiende ChangeNotifier para que la pantalla de Logros (y el botón del HUD)
// se redibujen al desbloquear uno nuevo. No mide nada por su cuenta: en cada
// actualización de posición, main le pasa las métricas actuales (celdas, POIs,
// % de ciudad, atalayas, colecciones completas) mediante [evaluate]; el
// controlador desbloquea los logros cuyo umbral se haya alcanzado y devuelve los
// recién conseguidos para que la UI los celebre. Guarda una "foto" de esas
// métricas para poder mostrar el progreso de los logros aún bloqueados.

import 'package:flutter/foundation.dart';

import 'achievement.dart';
import 'achievement_storage.dart';

class AchievementController extends ChangeNotifier {
  final AchievementStorage _storage;
  final List<Achievement> _all;

  final Set<String> _unlockedIds = <String>{};
  // Última lectura de cada métrica (para pintar el progreso de los bloqueados).
  final Map<AchievementMetric, int> _snapshot = {
    for (final m in AchievementMetric.values) m: 0,
  };
  bool _loaded = false;

  AchievementController({
    AchievementStorage? storage,
    List<Achievement>? achievements,
  })  : _storage = storage ?? AchievementStorage(),
        _all = achievements ?? kAchievements;

  /// Todos los logros conocidos (desbloqueados o no).
  List<Achievement> get all => _all;

  bool get isLoaded => _loaded;

  bool isUnlocked(Achievement a) => _unlockedIds.contains(a.id);
  bool isUnlockedId(String id) => _unlockedIds.contains(id);

  /// Cuántos logros se han desbloqueado en total.
  int get unlockedCount => _unlockedIds.length;
  int get totalCount => _all.length;

  /// Valor actual (último evaluado) de una métrica, para el progreso en la UI.
  int currentFor(AchievementMetric metric) => _snapshot[metric] ?? 0;

  /// IDs desbloqueados (copia; para el sync en la nube).
  Set<String> get unlockedIds => Set<String>.of(_unlockedIds);

  /// Une logros venidos de la nube con los locales, en silencio (como el
  /// desbloqueo retroactivo al cargar: sin toast). Devuelve cuántos eran
  /// nuevos.
  int mergeUnlocked(Iterable<String> ids) {
    final antes = _unlockedIds.length;
    _unlockedIds.addAll(ids);
    final nuevos = _unlockedIds.length - antes;
    if (nuevos > 0) {
      _storage.save(Set<String>.of(_unlockedIds));
      notifyListeners();
    }
    return nuevos;
  }

  /// Carga los logros desbloqueados guardados. Llamar una vez al arrancar.
  Future<void> load() async {
    _unlockedIds.addAll(await _storage.load());
    _loaded = true;
    notifyListeners();
  }

  /// Compara las métricas actuales con los umbrales y desbloquea los logros que
  /// toquen. Devuelve los recién desbloqueados (para celebrarlos); si no hay
  /// ninguno nuevo, no notifica ni guarda. Actualiza siempre la "foto" de
  /// métricas para que la pantalla muestre el progreso al día.
  List<Achievement> evaluate({
    required int cells,
    required int pois,
    required int cityPercent,
    required int watchtowers,
    required int collectionsComplete,
  }) {
    _snapshot[AchievementMetric.cells] = cells;
    _snapshot[AchievementMetric.pois] = pois;
    _snapshot[AchievementMetric.cityPercent] = cityPercent;
    _snapshot[AchievementMetric.watchtowers] = watchtowers;
    _snapshot[AchievementMetric.collections] = collectionsComplete;

    final nuevos = <Achievement>[];
    for (final a in _all) {
      if (_unlockedIds.contains(a.id)) continue;
      if (currentFor(a.metric) >= a.threshold) {
        _unlockedIds.add(a.id);
        nuevos.add(a);
      }
    }
    if (nuevos.isNotEmpty) {
      _storage.save(Set<String>.of(_unlockedIds));
    }
    // Aunque no haya desbloqueos, la foto cambió: redibuja barras de progreso.
    notifyListeners();
    return nuevos;
  }

  /// Borra los logros desbloqueados (útil para pruebas).
  void clear() {
    if (_unlockedIds.isEmpty) return;
    _unlockedIds.clear();
    _storage.save(<String>{});
    notifyListeners();
  }
}
