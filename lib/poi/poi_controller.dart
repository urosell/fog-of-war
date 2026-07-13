// Estado de los POIs: cuáles has descubierto y cuántos puntos llevas.
//
// Extiende ChangeNotifier para que el HUD y el mapa se redibujen solos cuando
// descubres uno nuevo. Detecta descubrimientos comparando tu posición con la de
// cada POI no descubierto: si pasas dentro del radio, lo marca y suma puntos.

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../fog/tile_math.dart';
import 'poi.dart';
import 'poi_storage.dart';

// El radio de descubrimiento es POR CATEGORÍA (PoiCategory.radiusMeters):
// grande para lugares extensos (plazas, parques, monumentos) que se visitan
// sin pasar por su coordenada central, y pequeño para puertas concretas
// (bares, tiendas), que exigen acercarse de verdad.

class PoiController extends ChangeNotifier {
  final PoiStorage _storage;
  List<Poi> _allPois;
  final Distance _distance = const Distance();

  final Set<String> _discoveredIds = <String>{};
  bool _loaded = false;

  PoiController({PoiStorage? storage, List<Poi>? pois})
      : _storage = storage ?? PoiStorage(),
        _allPois = pois ?? kBarcelonaPois {
    _rebuildIndex();
  }

  /// Todos los POIs conocidos (descubiertos o no).
  List<Poi> get allPois => _allPois;

  /// Mapa id→Poi, para resolver colecciones por ID rápido. Se recalcula al
  /// cambiar el pozo de POIs (ver [setPois]).
  Map<String, Poi> poiById = const {};

  // Índice espacial: POIs agrupados por tile Z16 (el mismo grid que usa la
  // niebla; ~300-460 m de lado en latitudes jugables). checkDiscoveries corre
  // en CADA lectura del GPS: con el índice solo mide distancias a los POIs del
  // tile de tu posición y sus 8 vecinos, en vez de a todos los del pozo (clave
  // cuando la hoja crezca a cientos o miles de POIs).
  Map<TileId, List<Poi>> _poisByTile = const {};

  // El vecindario 3x3 solo es correcto si ningún radio de descubrimiento
  // supera el lado de un tile. Margen holgado: el mayor actual es 120 m
  // (parque) y el lado ronda los 300 m incluso a latitud 60°.
  static const double _kMaxIndexableRadiusMeters = 250;

  void _rebuildIndex() {
    poiById = {for (final p in _allPois) p.id: p};
    assert(
      _allPois.every(
          (p) => p.category.radiusMeters <= _kMaxIndexableRadiusMeters),
      'Radio de descubrimiento mayor que un tile Z16: amplía el vecindario '
      'de checkDiscoveries antes de subir el radio.',
    );
    final byTile = <TileId, List<Poi>>{};
    for (final p in _allPois) {
      byTile
          .putIfAbsent(tileForCell(cellForLatLng(p.location)), () => <Poi>[])
          .add(p);
    }
    _poisByTile = byTile;
  }

  /// Reemplaza el pozo de POIs (p. ej. con el contenido cargado de la hoja). El
  /// conjunto de descubiertos (por id) se conserva: los ids que sigan existiendo
  /// quedan descubiertos; los que ya no estén, simplemente no se muestran.
  void setPois(List<Poi> pois) {
    _allPois = pois;
    _rebuildIndex();
    _recomputePoints();
    notifyListeners();
  }

  bool get isLoaded => _loaded;
  int get discoveredCount => _discoveredIds.length;
  int get totalCount => _allPois.length;

  bool isDiscovered(Poi poi) => _discoveredIds.contains(poi.id);

  /// Igual que [isDiscovered] pero por ID (lo usan las colecciones).
  bool isDiscoveredId(String id) => _discoveredIds.contains(id);

  /// POIs ya descubiertos (para dibujarlos en el mapa).
  List<Poi> get discoveredPois =>
      _allPois.where((p) => _discoveredIds.contains(p.id)).toList();

  /// Puntos totales = suma de los puntos de los POIs descubiertos. Derivado
  /// (no se guarda en disco) pero mantenido al vuelo: el HUD lo lee en cada
  /// tick de GPS y recorrer todo el pozo ahí no escala con miles de POIs.
  int get totalPoints => _totalPoints;
  int _totalPoints = 0;

  // Recalcula los puntos desde cero (al cargar, al cambiar el pozo de POIs o
  // al limpiar). En los descubrimientos basta con sumar el POI nuevo.
  void _recomputePoints() {
    var sum = 0;
    for (final poi in _allPois) {
      if (_discoveredIds.contains(poi.id)) sum += poi.points;
    }
    _totalPoints = sum;
  }

  /// Carga los POIs descubiertos guardados. Llamar una vez al arrancar.
  Future<void> load() async {
    _discoveredIds.addAll(await _storage.load());
    _recomputePoints();
    _loaded = true;
    notifyListeners();
  }

  /// Comprueba si [position] cae dentro del radio de algún POI no descubierto
  /// (el radio depende de la categoría del POI). Solo mira los POIs del tile
  /// Z16 de la posición y sus 8 vecinos (índice espacial; ver [_poisByTile]).
  /// Marca los nuevos como descubiertos, guarda y devuelve la lista de recién
  /// descubiertos (para que la UI los celebre). Si no hay ninguno, no notifica.
  List<Poi> checkDiscoveries(LatLng position) {
    final nuevos = <Poi>[];
    final centro = tileForCell(cellForLatLng(position));
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final candidatos = _poisByTile[TileId(centro.x + dx, centro.y + dy)];
        if (candidatos == null) continue;
        for (final poi in candidatos) {
          if (_discoveredIds.contains(poi.id)) continue;
          final metros =
              _distance.as(LengthUnit.Meter, position, poi.location);
          if (metros <= poi.category.radiusMeters) {
            _discoveredIds.add(poi.id);
            _totalPoints += poi.points;
            nuevos.add(poi);
          }
        }
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
    _totalPoints = 0;
    _storage.save(<String>{});
    notifyListeners();
  }
}
