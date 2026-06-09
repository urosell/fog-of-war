// Estado de los POIs: cuáles has descubierto y cuántos puntos llevas.
//
// Extiende ChangeNotifier para que el HUD y el mapa se redibujen solos cuando
// descubres uno nuevo. Detecta descubrimientos comparando tu posición con la de
// cada POI no descubierto: si pasas dentro del radio, lo marca y suma puntos.

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'poi.dart';
import 'poi_storage.dart';

/// Radio (en metros) para descubrir un POI. Más pequeño que el del fog (50 m)
/// para que haya que acercarse de verdad al sitio.
const double kPoiDiscoveryRadiusMeters = 30.0;

class PoiController extends ChangeNotifier {
  final PoiStorage _storage;
  final List<Poi> _allPois;
  final Distance _distance = const Distance();

  final Set<String> _discoveredIds = <String>{};
  bool _loaded = false;

  PoiController({PoiStorage? storage, List<Poi>? pois})
      : _storage = storage ?? PoiStorage(),
        _allPois = pois ?? kBarcelonaPois;

  /// Todos los POIs conocidos (descubiertos o no).
  List<Poi> get allPois => _allPois;

  bool get isLoaded => _loaded;
  int get discoveredCount => _discoveredIds.length;
  int get totalCount => _allPois.length;

  bool isDiscovered(Poi poi) => _discoveredIds.contains(poi.id);

  /// POIs ya descubiertos (para dibujarlos en el mapa).
  List<Poi> get discoveredPois =>
      _allPois.where((p) => _discoveredIds.contains(p.id)).toList();

  /// Puntos totales = suma de los puntos de los POIs descubiertos. Se calcula,
  /// no se guarda, así que se ajusta solo si cambian los valores.
  int get totalPoints {
    var sum = 0;
    for (final poi in _allPois) {
      if (_discoveredIds.contains(poi.id)) sum += poi.points;
    }
    return sum;
  }

  /// Carga los POIs descubiertos guardados. Llamar una vez al arrancar.
  Future<void> load() async {
    _discoveredIds.addAll(await _storage.load());
    _loaded = true;
    notifyListeners();
  }

  /// Comprueba si [position] cae dentro del radio de algún POI no descubierto.
  /// Marca los nuevos como descubiertos, guarda y devuelve la lista de recién
  /// descubiertos (para que la UI los celebre). Si no hay ninguno, no notifica.
  List<Poi> checkDiscoveries(LatLng position,
      {double radiusMeters = kPoiDiscoveryRadiusMeters}) {
    final nuevos = <Poi>[];
    for (final poi in _allPois) {
      if (_discoveredIds.contains(poi.id)) continue;
      final metros = _distance.as(LengthUnit.Meter, position, poi.location);
      if (metros <= radiusMeters) {
        _discoveredIds.add(poi.id);
        nuevos.add(poi);
      }
    }
    if (nuevos.isNotEmpty) {
      _storage.save(Set<String>.of(_discoveredIds));
      notifyListeners();
    }
    return nuevos;
  }

  /// Borra los POIs descubiertos (útil para pruebas).
  void clear() {
    if (_discoveredIds.isEmpty) return;
    _discoveredIds.clear();
    _storage.save(<String>{});
    notifyListeners();
  }
}
