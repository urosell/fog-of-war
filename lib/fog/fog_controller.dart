// Estado del fog of war: qué celdas ha descubierto el jugador.
//
// Por ahora se guarda solo en memoria (un Set de celdas). En un paso futuro
// añadiremos persistencia en disco (bitmaps) para que no se pierda al cerrar.
//
// Extiende ChangeNotifier: cuando cambian las celdas, llama a notifyListeners()
// y la interfaz que escuche (el mapa) se redibuja sola.

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'tile_math.dart';

/// Radio por defecto, en metros, que se desvela alrededor de cada posición.
const double kDefaultRevealRadiusMeters = 50.0;

class FogController extends ChangeNotifier {
  // Conjunto de celdas descubiertas. Un Set evita duplicados automáticamente:
  // desvelar la misma celda dos veces no cambia nada (operación idempotente).
  final Set<CellId> _discovered = <CellId>{};

  /// Vista de solo lectura de las celdas descubiertas (para dibujarlas).
  Set<CellId> get discovered => _discovered;

  /// Cuántas celdas se han descubierto en total.
  int get discoveredCount => _discovered.length;

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
      notifyListeners();
    }
    return huboCambios;
  }

  /// Borra todo lo descubierto (útil para pruebas).
  void clear() {
    if (_discovered.isEmpty) return;
    _discovered.clear();
    notifyListeners();
  }
}
