// Estado de las atalayas: cuáles has activado y qué POIs has avistado.
//
// Extiende ChangeNotifier para que el mapa se redibuje al activar una atalaya.
// Al moverte, comprueba si entras en el radio de activación de alguna atalaya no
// activada; si es así, la marca y añade al conjunto de "avistados" todos los
// POIs dentro de su radio de revelado. El conjunto de avistados se DERIVA de las
// atalayas activadas (no se guarda aparte), así si cambian radios o POIs se
// recalcula solo.

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../poi/poi.dart';
import 'watchtower.dart';
import 'watchtower_storage.dart';

class WatchtowerController extends ChangeNotifier {
  final WatchtowerStorage _storage;
  final List<Watchtower> _towers;
  final List<Poi> _pois;
  final Distance _distance = const Distance();

  final Set<String> _activatedIds = <String>{};
  final Set<String> _sightedPoiIds = <String>{};
  bool _loaded = false;

  WatchtowerController({
    WatchtowerStorage? storage,
    List<Watchtower>? towers,
    List<Poi>? pois,
  })  : _storage = storage ?? WatchtowerStorage(),
        _towers = towers ?? kBarcelonaWatchtowers,
        _pois = pois ?? kBarcelonaPois;

  /// Todas las atalayas (para dibujarlas en el mapa, siempre visibles).
  List<Watchtower> get towers => _towers;

  bool get isLoaded => _loaded;

  bool isActivated(Watchtower tower) => _activatedIds.contains(tower.id);

  /// ¿Está este POI avistado (revelado por una atalaya) por su ID?
  bool isSightedId(String poiId) => _sightedPoiIds.contains(poiId);

  /// Carga las atalayas activadas guardadas y recalcula los avistados. Llamar
  /// una vez al arrancar.
  Future<void> load() async {
    _activatedIds.addAll(await _storage.load());
    _recomputeSighted();
    _loaded = true;
    notifyListeners();
  }

  /// Comprueba si [position] cae dentro del radio de activación de alguna
  /// atalaya no activada. Activa las nuevas, recalcula los avistados, guarda y
  /// devuelve las atalayas recién activadas (para que la UI las anuncie). Si no
  /// hay ninguna nueva, no notifica.
  List<Watchtower> checkActivations(LatLng position) {
    final nuevas = <Watchtower>[];
    for (final tower in _towers) {
      if (_activatedIds.contains(tower.id)) continue;
      final metros = _distance.as(LengthUnit.Meter, position, tower.location);
      if (metros <= kWatchtowerActivationRadiusMeters) {
        _activatedIds.add(tower.id);
        _addSightedFor(tower);
        nuevas.add(tower);
      }
    }
    if (nuevas.isNotEmpty) {
      _storage.save(Set<String>.of(_activatedIds));
      notifyListeners();
    }
    return nuevas;
  }

  /// Cuántos POIs entran en el radio de revelado de [tower] (para el aviso).
  int sightedCountFor(Watchtower tower) {
    var count = 0;
    for (final poi in _pois) {
      if (_distance.as(LengthUnit.Meter, tower.location, poi.location) <=
          tower.revealRadiusMeters) {
        count++;
      }
    }
    return count;
  }

  /// Borra las atalayas activadas y los avistados (útil para pruebas).
  void clear() {
    if (_activatedIds.isEmpty && _sightedPoiIds.isEmpty) return;
    _activatedIds.clear();
    _sightedPoiIds.clear();
    _storage.save(<String>{});
    notifyListeners();
  }

  // Recalcula el conjunto de POIs avistados a partir de las atalayas activadas.
  void _recomputeSighted() {
    _sightedPoiIds.clear();
    for (final tower in _towers) {
      if (_activatedIds.contains(tower.id)) _addSightedFor(tower);
    }
  }

  // Añade a "avistados" los POIs dentro del radio de revelado de [tower].
  void _addSightedFor(Watchtower tower) {
    for (final poi in _pois) {
      if (_distance.as(LengthUnit.Meter, tower.location, poi.location) <=
          tower.revealRadiusMeters) {
        _sightedPoiIds.add(poi.id);
      }
    }
  }
}
