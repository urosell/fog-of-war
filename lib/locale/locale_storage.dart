// Almacenamiento del idioma elegido por el usuario.
//
// Guarda el código de idioma (p. ej. "es", "en", "ca", "fr") en un pequeño
// archivo de texto. Si no hay archivo, significa "seguir el idioma del sistema".
// Misma escritura atómica (temporal + rename) que el resto de almacenes.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocaleStorage {
  static const String _fileName = 'locale.txt';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// Lee el código de idioma guardado, o null si se sigue el del sistema.
  Future<String?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final code = (await file.readAsString()).trim();
      return code.isEmpty ? null : code;
    } catch (_) {
      return null;
    }
  }

  /// Guarda el código de idioma; null borra la preferencia (volver al sistema).
  Future<void> save(String? code) async {
    final file = await _file();
    if (code == null) {
      if (await file.exists()) await file.delete();
      return;
    }
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(code, flush: true);
    await tmp.rename(file.path);
  }
}
