// Almacenamiento del fog en disco.
//
// Guarda/lee el archivo binario del fog en la carpeta privada de la app
// (la que da path_provider). Usa el codec compacto de fog_codec.dart.
//
// La escritura es "atómica": primero escribe en un archivo temporal y luego lo
// renombra, para que un cierre inesperado no deje el archivo a medias/corrupto.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'fog_codec.dart';
import 'tile_math.dart';

class FogStorage {
  /// Nombre del archivo donde se guarda el fog.
  static const String _fileName = 'fog.bin';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// Lee las celdas descubiertas del disco. Si no hay archivo todavía
  /// (primer arranque), devuelve un conjunto vacío.
  Future<Set<CellId>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return <CellId>{};
      final bytes = await file.readAsBytes();
      return decodeFog(bytes);
    } catch (_) {
      // Ante cualquier error de lectura, empezar limpio en vez de crashear.
      return <CellId>{};
    }
  }

  /// Guarda las celdas descubiertas en el disco de forma atómica.
  Future<void> save(Set<CellId> cells) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(encodeFog(cells), flush: true);
    await tmp.rename(file.path);
  }
}
