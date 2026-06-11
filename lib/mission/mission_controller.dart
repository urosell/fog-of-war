// Estado de la "misión" activa: la colección que el jugador ha fijado.
//
// Cuando hay una misión fijada, el HUD muestra el progreso de esa colección
// (p. ej. 2/7) en vez del recuento global de POIs, y tocar el HUD la abre.
// Carga la preferencia al arrancar y la persiste al cambiarla.

import 'package:flutter/material.dart';

import '../poi/poi_collection.dart';
import 'mission_storage.dart';

class MissionController extends ChangeNotifier {
  final MissionStorage _storage;

  /// Colecciones entre las que se puede elegir misión.
  final List<PoiCollection> collections;

  String? _selectedId;

  MissionController({
    MissionStorage? storage,
    this.collections = kPoiCollections,
  }) : _storage = storage ?? MissionStorage();

  /// Id de la colección fijada, o null si no hay misión.
  String? get selectedId => _selectedId;

  /// ¿Hay una misión fijada?
  bool get hasMission => _selectedId != null;

  /// La colección fijada resuelta, o null si no hay (o ya no existe).
  PoiCollection? get selected {
    if (_selectedId == null) return null;
    for (final c in collections) {
      if (c.id == _selectedId) return c;
    }
    return null;
  }

  /// ¿Es [id] la misión fijada ahora mismo?
  bool isPinned(String id) => _selectedId == id;

  /// Carga la misión guardada (si la hay y sigue existiendo).
  Future<void> load() async {
    final id = await _storage.load();
    if (id == null) return;
    // Ignorar ids de colecciones que ya no existan.
    if (!collections.any((c) => c.id == id)) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Fija la colección [id] como misión (null = quitar la misión) y la guarda.
  void setMission(String? id) {
    if (id == _selectedId) return;
    _selectedId = id;
    notifyListeners();
    _storage.save(id);
  }

  /// Alterna: si [id] ya está fijada la quita, si no, la fija.
  void toggle(String id) => setMission(_selectedId == id ? null : id);
}
