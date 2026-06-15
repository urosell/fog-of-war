// Almacenamiento de las atalayas activadas.
//
// Guardamos solo el conjunto de IDs de atalayas activadas (lista de textos en
// JSON). Los POIs "avistados" NO se guardan: se recalculan a partir de las
// atalayas activadas y de los POIs dentro de su radio, así que si cambian
// radios o POIs, el avistado se ajusta solo. Escritura atómica (igual que
// PoiStorage / FogStorage).

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class WatchtowerStorage {
  static const String _fileName = 'watchtowers.json';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}/$_fileName');
  }

  /// Lee los IDs de atalayas activadas. Si no hay archivo o está corrupto,
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

  /// Guarda los IDs activados de forma atómica.
  Future<void> save(Set<String> ids) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(ids.toList()), flush: true);
    await tmp.rename(file.path);
  }
}
