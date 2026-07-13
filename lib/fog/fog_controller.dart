// Estado del fog of war: qué celdas ha descubierto el jugador.
//
// Mantiene las celdas en memoria (un Set) y las persiste en disco a través de
// FogStorage. Carga al arrancar y guarda automáticamente tras cada cambio,
// con un pequeño retardo (debounce) para agrupar varios desvelados seguidos en
// una sola escritura.
//
// Extiende ChangeNotifier: cuando cambian las celdas, llama a notifyListeners()
// y la interfaz que escuche (el mapa) se redibuja sola.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../cities/city.dart';
import 'fog_holes.dart';
import 'fog_storage.dart';
import 'tile_math.dart';

/// Radio por defecto, en metros, que se desvela alrededor de cada posición.
const double kDefaultRevealRadiusMeters = 50.0;

/// Tamaño máximo (en celdas) de un agujero cerrado que se autodescubre. Con
/// celdas de ~38 m, 4 celdas ≈ un microhueco por imprecisión del GPS. Poner 0
/// desactiva el autorrelleno.
const int kMaxAutoFillHoleCells = 4;

/// Cuánto se espera tras un cambio antes de guardar en disco.
const Duration _saveDebounce = Duration(seconds: 2);

// Recuento incremental de celdas descubiertas dentro de una ciudad. Los
// límites en celdas se calculan UNA vez (llevan trigonometría); después,
// contar una celda son cuatro comparaciones de enteros.
class _CityCellCounter {
  final City city;
  final int xMin, yMin, xMax, yMax;
  int count = 0;

  _CityCellCounter(this.city, ({int xMin, int yMin, int xMax, int yMax}) b)
      : xMin = b.xMin,
        yMin = b.yMin,
        xMax = b.xMax,
        yMax = b.yMax;

  bool contains(CellId c) =>
      c.x >= xMin && c.x <= xMax && c.y >= yMin && c.y <= yMax;
}

class FogController extends ChangeNotifier {
  final FogStorage _storage;

  // Conjunto de celdas descubiertas. Un Set evita duplicados automáticamente:
  // desvelar la misma celda dos veces no cambia nada (operación idempotente).
  final Set<CellId> _discovered = <CellId>{};

  // Las mismas celdas, agrupadas por su tile de almacenamiento Z16 (16x16
  // celdas por tile). Es el índice espacial que usa la capa de niebla para
  // recorrer SOLO las celdas de la zona visible, en vez de todas las
  // descubiertas en cada frame.
  final Map<TileId, List<CellId>> _byTile = <TileId, List<CellId>>{};

  // Celdas descubiertas DENTRO de cada ciudad, mantenidas al vuelo en _addCell.
  // Así el % del HUD y de los logros no recorren todo el conjunto en cada tick
  // de GPS (con años de juego serían cientos de miles de celdas).
  final List<_CityCellCounter> _cityCounters;

  // Contador que sube con cada cambio en las celdas. La capa de niebla lo usa
  // para saber si su máscara cacheada sigue valiendo o hay que rehacerla.
  int _revision = 0;

  Timer? _saveTimer;
  bool _loaded = false;

  FogController({FogStorage? storage, List<City> cities = kCities})
      : _storage = storage ?? FogStorage(),
        _cityCounters = [
          for (final c in cities) _CityCellCounter(c, c.cellBounds)
        ];

  /// Vista de solo lectura de las celdas descubiertas (para dibujarlas).
  Set<CellId> get discovered => _discovered;

  /// Celdas descubiertas agrupadas por tile Z16 (índice espacial de dibujo).
  Map<TileId, List<CellId>> get discoveredByTile => _byTile;

  /// Sube en cada cambio del conjunto de celdas (para invalidar cachés).
  int get revision => _revision;

  /// Cuántas celdas se han descubierto en total.
  int get discoveredCount => _discovered.length;

  /// Celdas descubiertas dentro de la ciudad [cityId] (recuento incremental,
  /// O(1)). 0 si la ciudad no está entre las del constructor.
  int discoveredCountInCity(String cityId) {
    for (final c in _cityCounters) {
      if (c.city.id == cityId) return c.count;
    }
    return 0;
  }

  /// True una vez que se han cargado los datos guardados.
  bool get isLoaded => _loaded;

  // Añade una celda al Set, al índice por tiles y a los contadores por ciudad
  // a la vez, para que nunca se desincronicen. Devuelve true si era nueva.
  bool _addCell(CellId cell) {
    if (!_discovered.add(cell)) return false;
    _byTile.putIfAbsent(tileForCell(cell), () => <CellId>[]).add(cell);
    for (final counter in _cityCounters) {
      if (counter.contains(cell)) counter.count++;
    }
    return true;
  }

  void _addCells(Iterable<CellId> cells) {
    for (final cell in cells) {
      _addCell(cell);
    }
  }

  /// Carga las celdas guardadas en disco. Llamar una vez al arrancar.
  Future<void> load() async {
    final guardadas = await _storage.load();
    _addCells(guardadas);
    _loaded = true;
    _revision++;
    notifyListeners();
  }

  /// Desvela todas las celdas dentro de [radiusMeters] alrededor de [position].
  /// Devuelve true si se descubrió alguna celda nueva (para evitar redibujar
  /// cuando no ha cambiado nada).
  bool reveal(LatLng position,
      {double radiusMeters = kDefaultRevealRadiusMeters}) {
    final nuevas = cellsWithinRadius(position, radiusMeters);
    final antes = _discovered.length;
    _addCells(nuevas);
    // Si se descubrió algo nuevo, rellenar microhuecos que hayan podido quedar
    // encerrados alrededor.
    if (_discovered.length != antes) {
      _rellenarHuecosAlrededor(nuevas);
    }
    final huboCambios = _discovered.length != antes;
    if (huboCambios) {
      _revision++;
      _scheduleSave();
      notifyListeners();
    }
    return huboCambios;
  }

  // Rellena agujeros pequeños y cerrados en una caja alrededor de las celdas
  // recién desveladas [nuevas]. La caja se amplía un margen para poder
  // comprobar que el agujero está realmente rodeado de celdas descubiertas.
  void _rellenarHuecosAlrededor(Set<CellId> nuevas) {
    if (kMaxAutoFillHoleCells <= 0 || nuevas.isEmpty) return;

    var minX = nuevas.first.x, maxX = nuevas.first.x;
    var minY = nuevas.first.y, maxY = nuevas.first.y;
    for (final c in nuevas) {
      if (c.x < minX) minX = c.x;
      if (c.x > maxX) maxX = c.x;
      if (c.y < minY) minY = c.y;
      if (c.y > maxY) maxY = c.y;
    }

    // Margen >= tamaño del agujero para detectar bien el "encierro".
    const margin = kMaxAutoFillHoleCells + 1;
    final huecos = findEnclosedHoles(
      _discovered,
      minX: minX - margin,
      minY: minY - margin,
      maxX: maxX + margin,
      maxY: maxY + margin,
      maxHoleCells: kMaxAutoFillHoleCells,
    );
    _addCells(huecos);
  }

  /// Borra todo lo descubierto (útil para pruebas).
  void clear() {
    if (_discovered.isEmpty) return;
    _discovered.clear();
    _byTile.clear();
    for (final counter in _cityCounters) {
      counter.count = 0;
    }
    _revision++;
    _scheduleSave();
    notifyListeners();
  }

  // Programa un guardado en disco tras un breve retardo, cancelando el anterior.
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, _saveNow);
  }

  /// Si hay un guardado pendiente (debounce), lo ejecuta ya. Llamar cuando la
  /// app pasa a segundo plano: si Android mata el proceso, no se pierden los
  /// últimos desvelados.
  Future<void> flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await _saveNow();
    }
  }

  // Guarda inmediatamente (copia el set para no leerlo mientras cambia).
  Future<void> _saveNow() async {
    await _storage.save(Set<CellId>.of(_discovered));
  }

  @override
  void dispose() {
    // Si había un guardado pendiente, hacerlo ahora antes de cerrar.
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      _saveNow();
    }
    super.dispose();
  }
}
