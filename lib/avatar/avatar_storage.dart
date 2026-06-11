// Almacenamiento de la personalización del marcador del jugador.
//
// Guarda dos índices (icono y color) en un pequeño JSON, con la misma escritura
// atómica (temporal + rename) que el resto de almacenes de la app.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AvatarStorage {
  static const String _fileName = 'avatar.json';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// Lee (iconIndex, colorIndex). Si no hay archivo o está corrupto, devuelve
  /// null para que el controller use los valores por defecto.
  Future<(int, int)?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final mapa = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return (mapa['icon'] as int, mapa['color'] as int);
    } catch (_) {
      return null;
    }
  }

  /// Guarda los índices de forma atómica.
  Future<void> save(int iconIndex, int colorIndex) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'icon': iconIndex, 'color': colorIndex}),
      flush: true,
    );
    await tmp.rename(file.path);
  }
}
