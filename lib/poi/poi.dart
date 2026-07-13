// Puntos de Interés (POIs): lugares destacados que dan puntos al descubrirlos
// pasando físicamente cerca.
//
// De momento la lista es CURADA (escrita a mano) con monumentos reales de
// Barcelona. Más adelante esta lista se sustituirá/ampliará con datos reales
// descargados de OpenStreetMap u Overture, sin tocar la mecánica del juego.

import 'package:latlong2/latlong.dart';

/// Categoría de un POI. Cada categoría da una cantidad de puntos distinta y
/// tiene su propio radio de descubrimiento.
///
/// El radio depende del TAMAÑO físico típico del lugar, porque la coordenada
/// del POI suele ser su centro: una plaza o un parque se deben descubrir al
/// cruzarlos por un borde (nadie pasa por el centro exacto), y la Sagrada
/// Família desde la acera (~60 m del centroide). En cambio bares, tiendas y
/// restaurantes son una puerta concreta: radio pequeño, que descubrirlos desde
/// la calle paralela sin haber estado les quitaría la gracia.
enum PoiCategory {
  monumento(label: 'Monumento', points: 50, radiusMeters: 80),
  iglesia(label: 'Iglesia', points: 45, radiusMeters: 80),
  museo(label: 'Museo', points: 40, radiusMeters: 50),
  parque(label: 'Parque', points: 30, radiusMeters: 120),
  mirador(label: 'Mirador', points: 25, radiusMeters: 50),
  plaza(label: 'Plaza', points: 20, radiusMeters: 100),
  tienda(label: 'Tienda', points: 15, radiusMeters: 30),
  michelin(label: 'Michelin', points: 60, radiusMeters: 30), // estrella
  tapas(label: 'Tapas', points: 20, radiusMeters: 30); // bares de tapas

  final String label;
  final int points;

  /// Radio (en metros) para descubrir un POI de esta categoría al pasar cerca.
  final double radiusMeters;

  const PoiCategory(
      {required this.label, required this.points, required this.radiusMeters});
}

/// Un punto de interés concreto en el mapa.
class Poi {
  /// Identificador estable (no cambia entre versiones). Se usa para guardar
  /// cuáles has descubierto.
  final String id;
  final String name;
  final LatLng location;
  final PoiCategory category;

  /// Enlace a Google Maps escrito a mano en la hoja (columna `maps_url`).
  /// Si está vacío, [mapsUrl] se genera solo desde las coordenadas.
  final String? customMapsUrl;

  // --- Ficha "marketiniana" (todo opcional; la UI degrada si falta) ---

  /// Foto de cabecera (columna `image_url`, solo https). Sin foto, la ficha
  /// pinta un degradado de la categoría.
  final String? imageUrl;

  /// Barrio para la línea "EIXAMPLE · BARCELONA" (columna `neighborhood`).
  final String? neighborhood;

  /// Valoración 0-5 escrita a mano en la hoja (columna `rating`).
  final double? rating;

  /// Duración estimada de la visita en minutos (columna `visit_min`).
  final int? visitMinutes;

  /// Cuánta gente lo exploró (columna `explored`). De momento manual; cuando
  /// haya backend será el contador real de jugadores.
  final int? exploredCount;

  /// Descripción evocadora por idioma (columnas `desc_es`, `desc_en`...).
  final Map<String, String> descriptions;

  const Poi({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    this.customMapsUrl,
    this.imageUrl,
    this.neighborhood,
    this.rating,
    this.visitMinutes,
    this.exploredCount,
    this.descriptions = const {},
  });

  /// Descripción en el idioma [code], con fallback a español o al primer
  /// idioma disponible. `null` si no hay ninguna (la UI omite el párrafo).
  String? localizedDescription(String code) =>
      descriptions[code] ??
      descriptions['es'] ??
      (descriptions.isNotEmpty ? descriptions.values.first : null);

  /// Puntos que otorga descubrir este POI (según su categoría).
  int get points => category.points;

  /// Enlace a Google Maps para este lugar: el personalizado de la hoja si lo
  /// hay, o uno generado desde lat/lon (búsqueda por coordenadas).
  String get mapsUrl {
    final custom = customMapsUrl?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return 'https://www.google.com/maps/search/?api=1'
        '&query=${location.latitude},${location.longitude}';
  }
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
  // --- Museos adicionales (para la colección "Museos") ---
  // NOTA: coordenadas APROXIMADAS, verificar antes de publicar.
  Poi(
    id: 'fundacio_miro',
    name: 'Fundació Joan Miró',
    location: LatLng(41.3686, 2.1601),
    category: PoiCategory.museo,
  ),
  Poi(
    id: 'macba',
    name: 'MACBA',
    location: LatLng(41.3831, 2.1668),
    category: PoiCategory.museo,
  ),
  Poi(
    id: 'cccb',
    name: 'CCCB',
    location: LatLng(41.3838, 2.1663),
    category: PoiCategory.museo,
  ),
  Poi(
    id: 'cosmocaixa',
    name: 'CosmoCaixa',
    location: LatLng(41.4112, 2.1346),
    category: PoiCategory.museo,
  ),
  Poi(
    id: 'museu_maritim',
    name: 'Museu Marítim de Barcelona',
    location: LatLng(41.3754, 2.1759),
    category: PoiCategory.museo,
  ),
  // --- Bares de tapas (colección "Tapas") ---
  // NOTA: coordenadas APROXIMADAS, verificar antes de publicar.
  Poi(
    id: 'cal_pep',
    name: 'Cal Pep',
    location: LatLng(41.3839, 2.1818),
    category: PoiCategory.tapas,
  ),
  Poi(
    id: 'el_xampanyet',
    name: 'El Xampanyet',
    location: LatLng(41.3845, 2.1812),
    category: PoiCategory.tapas,
  ),
  Poi(
    id: 'quimet_quimet',
    name: 'Quimet & Quimet',
    location: LatLng(41.3733, 2.1668),
    category: PoiCategory.tapas,
  ),
  Poi(
    id: 'bar_canete',
    name: 'Bar Cañete',
    location: LatLng(41.3786, 2.1709),
    category: PoiCategory.tapas,
  ),
  Poi(
    id: 'bar_del_pla',
    name: 'Bar del Pla',
    location: LatLng(41.3856, 2.1797),
    category: PoiCategory.tapas,
  ),
  Poi(
    id: 'la_cova_fumada',
    name: 'La Cova Fumada',
    location: LatLng(41.3792, 2.1893),
    category: PoiCategory.tapas,
  ),
  // --- Restaurantes con estrella Michelin (colección "Michelins") ---
  // NOTA: coordenadas APROXIMADAS, verificar antes de publicar.
  Poi(
    id: 'abac',
    name: 'ABaC',
    location: LatLng(41.4106, 2.1318),
    category: PoiCategory.michelin,
  ),
  Poi(
    id: 'lasarte',
    name: 'Lasarte',
    location: LatLng(41.3935, 2.1607),
    category: PoiCategory.michelin,
  ),
  Poi(
    id: 'disfrutar',
    name: 'Disfrutar',
    location: LatLng(41.3856, 2.1532),
    category: PoiCategory.michelin,
  ),
  Poi(
    id: 'moments',
    name: 'Moments',
    location: LatLng(41.3923, 2.1668),
    category: PoiCategory.michelin,
  ),
  Poi(
    id: 'cinc_sentits',
    name: 'Cinc Sentits',
    location: LatLng(41.3855, 2.1545),
    category: PoiCategory.michelin,
  ),
  Poi(
    id: 'enoteca_paco_perez',
    name: 'Enoteca Paco Pérez',
    location: LatLng(41.3855, 2.1960),
    category: PoiCategory.michelin,
  ),
];
