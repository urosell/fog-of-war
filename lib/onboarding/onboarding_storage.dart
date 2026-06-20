// Recuerda si el usuario ya vio la introducción ("¿de qué va el juego?").
//
// Guarda un pequeño archivo señal en disco: si existe, la intro ya se mostró y
// no se vuelve a enseñar. Mismo patrón de almacenamiento (un archivo en el
// directorio de documentos) que el resto de almacenes (ver locale_storage).

import 'dart:io';

import 'package:path_provider/path_provider.dart';

class OnboardingStorage {
  static const String _fileName = 'onboarding_seen.txt';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// ¿Ya se mostró la introducción alguna vez?
  Future<bool> hasSeen() async {
    try {
      return await (await _file()).exists();
    } catch (_) {
      return false;
    }
  }

  /// Marca la introducción como vista (no se volverá a mostrar).
  Future<void> markSeen() async {
    try {
      final file = await _file();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString('1', flush: true);
      await tmp.rename(file.path);
    } catch (_) {
      // Si no se puede escribir, en el peor caso la intro reaparece otra vez.
    }
  }
}
