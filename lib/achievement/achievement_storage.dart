// Almacenamiento de los logros desbloqueados.
//
// Guarda el conjunto de IDs de logros conseguidos (una lista de textos en
// JSON), con la misma escritura atómica (temporal + rename) que el resto de
// almacenes. Si el archivo no existe o está corrupto, se asume "ninguno".

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AchievementStorage {
  static const String _fileName = 'achievements.json';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// Lee los IDs de logros desbloqueados (conjunto vacío si no hay/está roto).
  Future<Set<String>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return <String>{};
      final contenido = await file.readAsString();
      final lista = jsonDecode(contenido) as List<dynamic>;
      return lista.map((e) => e as String).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Guarda los IDs desbloqueados de forma atómica.
  Future<void> save(Set<String> ids) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(ids.toList()), flush: true);
    await tmp.rename(file.path);
  }
}
