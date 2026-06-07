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

import 'fog_storage.dart';
import 'tile_math.dart';

/// Radio por defecto, en metros, que se desvela alrededor de cada posición.
const double kDefaultRevealRadiusMeters = 50.0;

/// Cuánto se espera tras un cambio antes de guardar en disco.
const Duration _saveDebounce = Duration(seconds: 2);

class FogController extends ChangeNotifier {
  final FogStorage _storage;

  // Conjunto de celdas descubiertas. Un Set evita duplicados automáticamente:
  // desvelar la misma celda dos veces no cambia nada (operación idempotente).
  final Set<CellId> _discovered = <CellId>{};

  Timer? _saveTimer;
  bool _loaded = false;

  FogController({FogStorage? storage}) : _storage = storage ?? FogStorage();

  /// Vista de solo lectura de las celdas descubiertas (para dibujarlas).
  Set<CellId> get discovered => _discovered;

  /// Cuántas celdas se han descubierto en total.
  int get discoveredCount => _discovered.length;

  /// True una vez que se han cargado los datos guardados.
  bool get isLoaded => _loaded;

  /// Carga las celdas guardadas en disco. Llamar una vez al arrancar.
  Future<void> load() async {
    final guardadas = await _storage.load();
    _discovered.addAll(guardadas);
    _loaded = true;
    notifyListeners();
  }

  /// Desvela todas las celdas dentro de [radiusMeters] alrededor de [position].
  /// Devuelve true si se descubrió alguna celda nueva (para evitar redibujar
  /// cuando no ha cambiado nada).
  bool reveal(LatLng position,
      {double radiusMeters = kDefaultRevealRadiusMeters}) {
    final nuevas = cellsWithinRadius(position, radiusMeters);
    final antes = _discovered.length;
    _discovered.addAll(nuevas);
    final huboCambios = _discovered.length != antes;
    if (huboCambios) {
      _scheduleSave();
      notifyListeners();
    }
    return huboCambios;
  }

  /// Borra todo lo descubierto (útil para pruebas).
  void clear() {
    if (_discovered.isEmpty) return;
    _discovered.clear();
    _scheduleSave();
    notifyListeners();
  }

  // Programa un guardado en disco tras un breve retardo, cancelando el anterior.
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, _saveNow);
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
