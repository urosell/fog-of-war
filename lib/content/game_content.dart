// Contenido del juego: el conjunto de POIs y colecciones que la app muestra.
//
// Puede venir de tres sitios (ver content_repository.dart): la SEMILLA embebida
// (las listas const de siempre), la CACHÉ en disco (última descarga buena) o la
// hoja REMOTA. Sea cual sea el origen, el resto de la app consume este objeto.

import '../poi/poi.dart';
import '../poi/poi_collection.dart';

class GameContent {
  final List<Poi> pois;
  final List<PoiCollection> collections;

  const GameContent({required this.pois, required this.collections});

  /// Contenido semilla: las listas curadas a mano embebidas en la app. Es el
  /// punto de partida instantáneo y el último recurso si no hay caché ni red.
  factory GameContent.seed() => const GameContent(
        pois: kBarcelonaPois,
        collections: kPoiCollections,
      );

  bool get isEmpty => pois.isEmpty && collections.isEmpty;
}
