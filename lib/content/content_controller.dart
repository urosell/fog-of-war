// Orquesta de dónde sale el contenido del juego.
//
// Modelo "se aplica al arrancar" (acordado con el usuario):
//   - loadInitial(): deja listo el contenido AL INSTANTE = caché en disco
//     (última descarga buena) o, si no hay, la SEMILLA embebida.
//   - refreshForNextLaunch(): descarga la hoja en segundo plano y, si es válida,
//     la guarda en caché. NO cambia lo que se ve en esta sesión: los cambios de
//     la hoja aparecen en el PRÓXIMO arranque. Así nunca hay saltos a media
//     partida ni pantallas a medio cargar.
//
// El progreso del usuario (POIs descubiertos, puntos, misión) vive aparte,
// indexado por id, así que refrescar el contenido NO lo toca.

import 'package:flutter/foundation.dart';

import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import '../watchtower/watchtower.dart';
import 'content_config.dart';
import 'content_parser.dart';
import 'content_repository.dart';
import 'game_content.dart';

class ContentController extends ChangeNotifier {
  final ContentRepository _repo;

  ContentController({ContentRepository? repository})
      : _repo = repository ?? ContentRepository();

  GameContent _content = GameContent.seed();
  GameContent get content => _content;

  /// Atajos al contenido actual (POIs, colecciones y atalayas).
  List<Poi> get pois => _content.pois;
  List<PoiCollection> get collections => _content.collections;
  List<Watchtower> get watchtowers => _content.watchtowers;

  /// Deja el contenido listo para usar YA: caché si la hay, si no la semilla.
  Future<void> loadInitial() async {
    final cached = await _repo.readCache();
    if (cached != null) _tryApply(cached);
  }

  /// Descarga la hoja y, si es válida, la cachea para el próximo arranque.
  /// No toca el contenido en uso. Cualquier fallo (sin red, hoja mal, etc.) se
  /// traga: simplemente se seguirá usando la caché/semilla actual.
  Future<void> refreshForNextLaunch() async {
    final id = kSpreadsheetId;
    if (id == null) return;
    try {
      final remote = await _repo.fetchRemote(id);
      // Validamos parseando: si el CSV está roto, parseContent lanza y NO
      // cacheamos basura.
      parseContent(remote.poisCsv, remote.collectionsCsv,
          remote.watchtowersCsv);
      await _repo.writeCache(remote);
    } catch (e) {
      if (kDebugMode) debugPrint('[content] descarga fallida: $e');
    }
  }

  // Parsea y aplica al contenido en uso. Si el parseo falla, conserva lo previo.
  bool _tryApply(RawContent raw) {
    try {
      _content = parseContent(
          raw.poisCsv, raw.collectionsCsv, raw.watchtowersCsv);
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[content] CSV inválido, se conserva: $e');
      return false;
    }
  }
}
