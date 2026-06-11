// Almacenamiento de la "misión" activa: el id de la colección fijada.
//
// Guarda el id en un pequeño archivo de texto. Sin archivo = no hay misión
// fijada (los indicadores muestran el progreso global). Misma escritura
// atómica que el resto de almacenes de la app.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

class MissionStorage {
  static const String _fileName = 'mission.txt';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// Lee el id de la colección fijada, o null si no hay misión.
  Future<String?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final id = (await file.readAsString()).trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Guarda el id (null borra la misión fijada).
  Future<void> save(String? id) async {
    final file = await _file();
    if (id == null) {
      if (await file.exists()) await file.delete();
      return;
    }
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(id, flush: true);
    await tmp.rename(file.path);
  }
}
