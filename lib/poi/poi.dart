// Puntos de Interés (POIs): lugares destacados que dan puntos al descubrirlos
// pasando físicamente cerca.
//
// De momento la lista es CURADA (escrita a mano) con monumentos reales de
// Barcelona. Más adelante esta lista se sustituirá/ampliará con datos reales
// descargados de OpenStreetMap u Overture, sin tocar la mecánica del juego.

import 'package:latlong2/latlong.dart';

/// Categoría de un POI. Cada categoría da una cantidad de puntos distinta.
enum PoiCategory {
  monumento(label: 'Monumento', points: 50),
  iglesia(label: 'Iglesia', points: 45),
  museo(label: 'Museo', points: 40),
  parque(label: 'Parque', points: 30),
  mirador(label: 'Mirador', points: 25),
  plaza(label: 'Plaza', points: 20),
  tienda(label: 'Tienda', points: 15);

  final String label;
  final int points;

  const PoiCategory({required this.label, required this.points});
}

/// Un punto de interés concreto en el mapa.
class Poi {
  /// Identificador estable (no cambia entre versiones). Se usa para guardar
  /// cuáles has descubierto.
  final String id;
  final String name;
  final LatLng location;
  final PoiCategory category;

  const Poi({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
  });

  /// Puntos que otorga descubrir este POI (según su categoría).
  int get points => category.points;
}

/// "Pozo" común de POIs: TODOS los lugares conocidos de Barcelona.
///
/// Las colecciones temáticas (ver `poi_collection.dart`) no tienen sus propios
/// POIs: simplemente referencian por ID a los de esta lista. Así un mismo lugar
/// (p. ej. la Sagrada Família) puede pertenecer a varias colecciones a la vez.
const List<Poi> kBarcelonaPois = [
  Poi(
    id: 'sagrada_familia',
    name: 'Sagrada Família',
    location: LatLng(41.4036, 2.1744),
    category: PoiCategory.iglesia,
  ),
  Poi(
    id: 'park_guell',
    name: 'Park Güell',
    location: LatLng(41.4145, 2.1527),
    category: PoiCategory.parque,
  ),
  Poi(
    id: 'casa_batllo',
    name: 'Casa Batlló',
    location: LatLng(41.3916, 2.1649),
    category: PoiCategory.monumento,
  ),
  Poi(
    id: 'la_pedrera',
    name: 'La Pedrera (Casa Milà)',
    location: LatLng(41.3954, 2.1619),
    category: PoiCategory.monumento,
  ),
  Poi(
    id: 'catedral_bcn',
    name: 'Catedral de Barcelona',
    location: LatLng(41.3839, 2.1762),
    category: PoiCategory.iglesia,
  ),
  Poi(
    id: 'placa_catalunya',
    name: 'Plaça de Catalunya',
    location: LatLng(41.3870, 2.1700),
    category: PoiCategory.plaza,
  ),
  Poi(
    id: 'arc_triomf',
    name: 'Arc de Triomf',
    location: LatLng(41.3910, 2.1806),
    category: PoiCategory.monumento,
  ),
  Poi(
    id: 'museu_picasso',
    name: 'Museu Picasso',
    location: LatLng(41.3851, 2.1807),
    category: PoiCategory.museo,
  ),
  Poi(
    id: 'mnac',
    name: "Museu Nacional d'Art de Catalunya",
    location: LatLng(41.3685, 2.1533),
    category: PoiCategory.museo,
  ),
  Poi(
    id: 'parc_ciutadella',
    name: 'Parc de la Ciutadella',
    location: LatLng(41.3884, 2.1869),
    category: PoiCategory.parque,
  ),
  Poi(
    id: 'mirador_colom',
    name: 'Mirador de Colom',
    location: LatLng(41.3759, 2.1774),
    category: PoiCategory.mirador,
  ),
  Poi(
    id: 'bunkers_carmel',
    name: 'Bunkers del Carmel',
    location: LatLng(41.4194, 2.1622),
    category: PoiCategory.mirador,
  ),
  Poi(
    id: 'castell_montjuic',
    name: 'Castell de Montjuïc',
    location: LatLng(41.3631, 2.1656),
    category: PoiCategory.monumento,
  ),
  Poi(
    id: 'tibidabo',
    name: 'Tibidabo (Sagrat Cor)',
    location: LatLng(41.4225, 2.1187),
    category: PoiCategory.mirador,
  ),
  // --- Obras de Gaudí adicionales (para la colección "Ruta Gaudí") ---
  Poi(
    id: 'casa_vicens',
    name: 'Casa Vicens',
    location: LatLng(41.4036, 2.1518),
    category: PoiCategory.monumento,
  ),
  Poi(
    id: 'palau_guell',
    name: 'Palau Güell',
    location: LatLng(41.3793, 2.1742),
    category: PoiCategory.monumento,
  ),
  Poi(
    id: 'torre_bellesguard',
    name: 'Torre Bellesguard',
    location: LatLng(41.4186, 2.1320),
    category: PoiCategory.monumento,
  ),
  // --- Ejemplo de otro tema: tiendas "otaku"/cómic (colección "Otaku BCN") ---
  // NOTA: coordenadas APROXIMADAS, verificar antes de publicar.
  Poi(
    id: 'norma_comics',
    name: 'Norma Cómics',
    location: LatLng(41.3922, 2.1806),
    category: PoiCategory.tienda,
  ),
  Poi(
    id: 'gigamesh',
    name: 'Llibreria Gigamesh',
    location: LatLng(41.3908, 2.1797),
    category: PoiCategory.tienda,
  ),
];
