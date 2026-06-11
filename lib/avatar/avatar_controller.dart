// Estado de la personalización del marcador del jugador.
//
// Mantiene los índices de icono y color elegidos, los carga del disco al
// arrancar y los persiste al cambiarlos. Al ser un ChangeNotifier, el marcador
// del mapa y la pantalla de Ajustes se redibujan solos cuando algo cambia.

import 'package:flutter/material.dart';

import 'avatar.dart';
import 'avatar_storage.dart';

class AvatarController extends ChangeNotifier {
  final AvatarStorage _storage;

  int _iconIndex = 0;
  int _colorIndex = 0;

  AvatarController([AvatarStorage? storage])
      : _storage = storage ?? AvatarStorage();

  int get iconIndex => _iconIndex;
  int get colorIndex => _colorIndex;
  IconData get icon => kAvatarIcons[_iconIndex];
  Color get color => kAvatarColors[_colorIndex];

  /// Carga los índices guardados (si los hay). Se ignoran valores fuera de
  /// rango por si el catálogo cambió entre versiones.
  Future<void> load() async {
    final guardado = await _storage.load();
    if (guardado == null) return;
    _iconIndex = guardado.$1.clamp(0, kAvatarIcons.length - 1);
    _colorIndex = guardado.$2.clamp(0, kAvatarColors.length - 1);
    notifyListeners();
  }

  void setIcon(int index) {
    if (index == _iconIndex) return;
    _iconIndex = index;
    notifyListeners();
    _storage.save(_iconIndex, _colorIndex);
  }

  void setColor(int index) {
    if (index == _colorIndex) return;
    _colorIndex = index;
    notifyListeners();
    _storage.save(_iconIndex, _colorIndex);
  }
}
