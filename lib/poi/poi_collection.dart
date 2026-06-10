// Colecciones temáticas de POIs (p. ej. "Ruta Gaudí", "Otaku BCN").
//
// Una colección NO contiene POIs propios: referencia por ID a los del "pozo"
// común (`kBarcelonaPois` en poi.dart). De este modo un mismo lugar puede
// pertenecer a varias colecciones y, al descubrirlo una sola vez, cuenta para
// todas. La idea de juego: distintos jugadores quieren "completar" temas
// distintos (la obra de Gaudí, los rincones otaku, los miradores...).

import 'package:flutter/material.dart';

import 'poi.dart';

/// Una colección temática: un nombre, un look (icono + color) y la lista de IDs
/// de POIs que la forman.
class PoiCollection {
  /// Identificador estable (no cambia entre versiones).
  final String id;
  final String name;

  /// Frase corta que explica el tema ("Toda la obra de Antoni Gaudí...").
  final String description;

  /// Icono y color de acento para pintar la colección en la UI.
  final IconData icon;
  final Color accent;

  /// IDs de los POIs que componen la colección (en orden de presentación).
  /// Deben existir en `kBarcelonaPois`.
  final List<String> poiIds;

  const PoiCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.poiIds,
  });

  /// Resuelve los IDs a objetos Poi reales, en el orden de [poiIds] y omitiendo
  /// los que no existan en el pozo. [byId] es un mapa id→Poi (lo da el
  /// PoiController para no recalcularlo cada vez).
  List<Poi> resolvePois(Map<String, Poi> byId) {
    final result = <Poi>[];
    for (final id in poiIds) {
      final poi = byId[id];
      if (poi != null) result.add(poi);
    }
    return result;
  }

  /// Cuántos POIs de esta colección están descubiertos, según [isDiscoveredId].
  int discoveredCount(bool Function(String id) isDiscoveredId) {
    var n = 0;
    for (final id in poiIds) {
      if (isDiscoveredId(id)) n++;
    }
    return n;
  }
}

/// Colecciones temáticas iniciales de Barcelona.
///
/// Para añadir un tema nuevo (otra ruta, otra afición...) basta con escribir
/// otra `PoiCollection` aquí referenciando IDs de POIs del pozo. Si necesitas
/// lugares que aún no existen, añádelos primero a `kBarcelonaPois`.
const List<PoiCollection> kPoiCollections = [
  PoiCollection(
    id: 'gaudi',
    name: 'Ruta Gaudí',
    description: 'La obra modernista de Antoni Gaudí por Barcelona.',
    icon: Icons.architecture,
    accent: Color(0xFF6BCB77), // verde modernista
    poiIds: [
      'sagrada_familia',
      'casa_batllo',
      'la_pedrera',
      'park_guell',
      'casa_vicens',
      'palau_guell',
      'torre_bellesguard',
    ],
  ),
  PoiCollection(
    id: 'imprescindibles',
    name: 'Imprescindibles de Barcelona',
    description: 'Los lugares que no te puedes perder en la ciudad.',
    icon: Icons.star,
    accent: Color(0xFFFFB300), // ámbar "tesoro"
    poiIds: [
      'sagrada_familia',
      'park_guell',
      'catedral_bcn',
      'casa_batllo',
      'la_pedrera',
      'mnac',
      'castell_montjuic',
      'parc_ciutadella',
      'tibidabo',
    ],
  ),
  PoiCollection(
    id: 'otaku',
    name: 'Otaku BCN (ejemplo)',
    description: 'Templos del cómic, el manga y la cultura geek.',
    icon: Icons.auto_awesome,
    accent: Color(0xFFE85D9E), // rosa "anime"
    poiIds: [
      'norma_comics',
      'gigamesh',
    ],
  ),
];
