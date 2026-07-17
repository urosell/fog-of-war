// Contenido del juego: POIs, colecciones y atalayas que la app muestra.
//
// Puede venir de tres sitios (ver content_repository.dart): la SEMILLA embebida
// (las listas const de siempre), la CACHÉ en disco (última descarga buena) o la
// hoja REMOTA. Sea cual sea el origen, el resto de la app consume este objeto.

import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import '../watchtower/watchtower.dart';

class GameContent {
  final List<Poi> pois;
  final List<PoiCollection> collections;
  final List<Watchtower> watchtowers;

  const GameContent({
    required this.pois,
    required this.collections,
    this.watchtowers = kBarcelonaWatchtowers,
  });

  /// Contenido semilla: las listas curadas a mano embebidas en la app. Es el
  /// punto de partida instantáneo y el último recurso si no hay caché ni red.
  factory GameContent.seed() => const GameContent(
        pois: kBarcelonaPois,
        collections: kPoiCollections,
        watchtowers: kBarcelonaWatchtowers,
      );

  bool get isEmpty => pois.isEmpty && collections.isEmpty;
}
