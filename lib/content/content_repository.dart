// De dónde sale el contenido: caché en disco (última descarga buena) y la hoja
// remota. La semilla vive en GameContent.seed(); aquí gestionamos los dos
// orígenes "vivos". Cacheamos el CSV en crudo (texto), así el parseo es siempre
// el mismo camino y no hay que serializar iconos/colores.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'content_config.dart';

/// Las pestañas de la hoja en texto CSV.
class RawContent {
  final String poisCsv;
  final String collectionsCsv;
  final String watchtowersCsv;
  const RawContent(this.poisCsv, this.collectionsCsv,
      [this.watchtowersCsv = '']);
}

class ContentRepository {
  static const _poisFile = 'content_pois.csv';
  static const _collectionsFile = 'content_collections.csv';
  static const _watchtowersFile = 'content_watchtowers.csv';

  Future<Directory> _dir() async => getApplicationDocumentsDirectory();

  /// Lee el CSV cacheado de una descarga previa. null si no hay caché completa.
  /// El de atalayas es opcional (cachés de versiones sin esa pestaña): si
  /// falta, va vacío y el parser cae a la semilla.
  Future<RawContent?> readCache() async {
    try {
      final dir = await _dir();
      final pois = File('${dir.path}/$_poisFile');
      final colls = File('${dir.path}/$_collectionsFile');
      if (!await pois.exists() || !await colls.exists()) return null;
      final towers = File('${dir.path}/$_watchtowersFile');
      return RawContent(
        await pois.readAsString(),
        await colls.readAsString(),
        await towers.exists() ? await towers.readAsString() : '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Guarda en disco el CSV recién descargado.
  Future<void> writeCache(RawContent content) async {
    final dir = await _dir();
    await File('${dir.path}/$_poisFile').writeAsString(content.poisCsv);
    await File('${dir.path}/$_collectionsFile')
        .writeAsString(content.collectionsCsv);
    await File('${dir.path}/$_watchtowersFile')
        .writeAsString(content.watchtowersCsv);
  }

  /// Descarga las pestañas de la hoja. Lanza si falla la red o el HTTP.
  Future<RawContent> fetchRemote(String spreadsheetId) async {
    final pois = await _get(sheetCsvUrl(spreadsheetId, kPoisSheetName));
    final colls = await _get(sheetCsvUrl(spreadsheetId, kCollectionsSheetName));
    // OJO: si la pestaña no existe, gviz devuelve la PRIMERA pestaña con
    // HTTP 200 (no un error). El parser lo detecta por la cabecera (exige
    // radius_m) y cae a la semilla; ver _parseWatchtowers.
    final towers = await _get(sheetCsvUrl(spreadsheetId, kWatchtowersSheetName));
    return RawContent(pois, colls, towers);
  }

  Future<String> _get(String url) async {
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode} al pedir $url');
    }
    return res.body;
  }
}
