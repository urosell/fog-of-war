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

  /// Nombre y descripción por idioma (clave = código de idioma: 'es','en',...).
  /// Vacíos en la semilla `const`; los rellena el contenido descargado de la
  /// hoja. Si falta el idioma pedido, se cae a [name]/[description].
  final Map<String, String> names;
  final Map<String, String> descriptions;

  const PoiCollection({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.poiIds,
    this.names = const {},
    this.descriptions = const {},
  });

  /// Nombre en el idioma [code], con fallback al nombre base.
  String localizedName(String code) => names[code] ?? name;

  /// Descripción en el idioma [code], con fallback a la descripción base.
  String localizedDescription(String code) => descriptions[code] ?? description;

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
    names: {
      'es': 'Ruta Gaudí',
      'en': 'Gaudí Route',
      'ca': 'Ruta Gaudí',
      'fr': 'Route Gaudí',
    },
    descriptions: {
      'es': 'La obra modernista de Antoni Gaudí por Barcelona.',
      'en': "Antoni Gaudí's modernist work across Barcelona.",
      'ca': "L'obra modernista d'Antoni Gaudí per Barcelona.",
      'fr': "L'œuvre moderniste d'Antoni Gaudí à travers Barcelone.",
    },
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
    names: {
      'es': 'Imprescindibles de Barcelona',
      'en': 'Barcelona Essentials',
      'ca': 'Imprescindibles de Barcelona',
      'fr': 'Incontournables de Barcelone',
    },
    descriptions: {
      'es': 'Los lugares que no te puedes perder en la ciudad.',
      'en': 'The must-see places in the city.',
      'ca': "Els llocs que no et pots perdre a la ciutat.",
      'fr': 'Les lieux à ne pas manquer dans la ville.',
    },
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
    names: {
      'es': 'Otaku BCN (ejemplo)',
      'en': 'Otaku BCN (example)',
      'ca': 'Otaku BCN (exemple)',
      'fr': 'Otaku BCN (exemple)',
    },
    descriptions: {
      'es': 'Templos del cómic, el manga y la cultura geek.',
      'en': 'Temples of comics, manga and geek culture.',
      'ca': 'Temples del còmic, el manga i la cultura geek.',
      'fr': 'Temples de la BD, du manga et de la culture geek.',
    },
    icon: Icons.auto_awesome,
    accent: Color(0xFFE85D9E), // rosa "anime"
    poiIds: [
      'norma_comics',
      'gigamesh',
    ],
  ),
  PoiCollection(
    id: 'museos',
    name: 'Museos de Barcelona',
    description: 'Los grandes museos de la ciudad.',
    names: {
      'es': 'Museos de Barcelona',
      'en': 'Barcelona Museums',
      'ca': 'Museus de Barcelona',
      'fr': 'Musées de Barcelone',
    },
    descriptions: {
      'es': 'Los grandes museos de la ciudad.',
      'en': "The city's great museums.",
      'ca': 'Els grans museus de la ciutat.',
      'fr': 'Les grands musées de la ville.',
    },
    icon: Icons.museum,
    accent: Color(0xFF5C8DF6), // azul "cultura"
    poiIds: [
      'museu_picasso',
      'mnac',
      'fundacio_miro',
      'macba',
      'cccb',
      'cosmocaixa',
      'museu_maritim',
    ],
  ),
  PoiCollection(
    id: 'tapas',
    name: 'Ruta de Tapas',
    description: 'Bares de tapas con solera de Barcelona.',
    names: {
      'es': 'Ruta de Tapas',
      'en': 'Tapas Trail',
      'ca': 'Ruta de Tapes',
      'fr': 'Route des Tapas',
    },
    descriptions: {
      'es': 'Bares de tapas con solera de Barcelona.',
      'en': "Barcelona's classic tapas bars.",
      'ca': 'Bars de tapes amb solera de Barcelona.',
      'fr': 'Les bars à tapas typiques de Barcelone.',
    },
    icon: Icons.tapas,
    accent: Color(0xFFE8743B), // naranja "pimentón"
    poiIds: [
      'cal_pep',
      'el_xampanyet',
      'quimet_quimet',
      'bar_canete',
      'bar_del_pla',
      'la_cova_fumada',
    ],
  ),
  PoiCollection(
    id: 'michelins',
    name: 'Estrellas Michelin',
    description: 'Alta cocina con estrella en Barcelona.',
    names: {
      'es': 'Estrellas Michelin',
      'en': 'Michelin Stars',
      'ca': 'Estrelles Michelin',
      'fr': 'Étoiles Michelin',
    },
    descriptions: {
      'es': 'Alta cocina con estrella en Barcelona.',
      'en': "Barcelona's starred fine dining.",
      'ca': 'Alta cuina amb estrella a Barcelona.',
      'fr': 'La haute gastronomie étoilée de Barcelone.',
    },
    icon: Icons.restaurant,
    accent: Color(0xFFCE1A3B), // rojo "Michelin"
    poiIds: [
      'abac',
      'lasarte',
      'disfrutar',
      'moments',
      'cinc_sentits',
      'enoteca_paco_perez',
    ],
  ),
];
