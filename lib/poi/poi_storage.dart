// Almacenamiento de los POIs descubiertos.
//
// Solo guardamos el conjunto de IDs descubiertos (una lista de textos en JSON).
// Los puntos NO se guardan: se recalculan sumando los puntos de los POIs
// descubiertos, así que si algún día cambian los valores, el total se ajusta
// solo. Escritura atómica (temporal + rename) como en FogStorage.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class PoiStorage {
  static const String _fileName = 'pois.json';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// Lee los IDs de POIs descubiertos. Si no hay archivo o está corrupto,
  /// devuelve un conjunto vacío en vez de fallar.
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

  /// Guarda los IDs descubiertos de forma atómica.
  Future<void> save(Set<String> ids) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(ids.toList()), flush: true);
    await tmp.rename(file.path);
  }
}
