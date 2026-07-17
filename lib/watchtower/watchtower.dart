// Atalayas: miradores a los que llegas para "avistar" la zona.
//
// Mecánica (scouting): al acercarte a una atalaya, se revelan en el mapa TODOS
// los POIs dentro de su radio, pero NO como descubiertos: aparecen con un icono
// gris ("avistado"). Para descubrirlos de verdad (icono dorado + puntos) sigues
// teniendo que ir físicamente a cada uno. La niebla no cambia: la atalaya solo
// muestra dónde están los puntos de interés de esa zona.
//
// Las atalayas NO puntúan por sí mismas: son puramente un disparador de avistado.

import 'package:latlong2/latlong.dart';

/// Distancia (en metros) a la que activas una atalaya al acercarte. Algo mayor
/// que el radio de descubrimiento de POIs (30 m) porque son miradores amplios.
const double kWatchtowerActivationRadiusMeters = 70.0;

/// Radio (en metros) que "avista" una atalaya: los POIs dentro de él se revelan.
const double kWatchtowerRevealRadiusMeters = 600.0;

/// Una atalaya: un mirador que, al alcanzarlo, revela los POIs de su entorno.
class Watchtower {
  /// Identificador estable (para guardar cuáles has activado).
  final String id;
  final String name;
  final LatLng location;

  /// Radio en metros dentro del cual se avistan los POIs.
  final double revealRadiusMeters;

  const Watchtower({
    required this.id,
    required this.name,
    required this.location,
    this.revealRadiusMeters = kWatchtowerRevealRadiusMeters,
  });
}

/// SEMILLA de atalayas de Barcelona. Desde que existe la pestaña `Watchtowers`
/// de la Google Sheet (ver docs/sheet/README.md), la lista viva se edita ALLÍ:
/// esta copia embebida solo se usa de arranque en frío y de respaldo si la
/// pestaña falta o no valida. Cada atalaya está ANCLADA a un lugar real y
/// reconocible (una plaza, un mirador, un mercado...) y su nombre es ese
/// lugar, para que el jugador sepa exactamente adónde ir. Las coordenadas y
/// el radio están verificados con `dart run tool/watchtower_coverage.dart`
/// (qué avista cada una y qué POIs quedan huérfanos); el círculo del modo
/// admin enseña el rango sobre el mapa. Sin cubrir a propósito: Tibidabo y
/// Búnkers del Carmel, que ya son miradores en sí mismos.
///
/// Los IDs de las 5 primeras son anteriores a esta colocación y NO se tocan
/// (hay activaciones guardadas en disco y en la nube).
const List<Watchtower> kBarcelonaWatchtowers = [
  // La plaza de la Catedral: Picasso, Born (tapas), Palau Güell. Radio 650
  // para llegar también a Pl. Catalunya (a ~620 m).
  Watchtower(
    id: 'atalaya_gotica',
    name: 'Pla de la Seu',
    location: LatLng(41.3841, 2.1756),
    revealRadiusMeters: 650,
  ),
  // El mercado de la dreta de l'Eixample: Casa Batlló, La Pedrera, Lasarte
  // y Moments.
  Watchtower(
    id: 'atalaya_eixample',
    name: 'Mercat de la Concepció',
    location: LatLng(41.3950, 2.1662),
  ),
  // El monumento a Colón ES un mirador con ascensor: Museu Marítim y Palau
  // Güell (y el propio POI del mirador).
  Watchtower(
    id: 'atalaya_port',
    name: 'Mirador de Colom',
    location: LatLng(41.3759, 2.1774),
  ),
  // La estación del teleférico (Parc de Montjuïc): desde la cabina se ve la
  // montaña entera — radio 800 y caen Castell, MNAC y Fundació Miró.
  Watchtower(
    id: 'atalaya_montjuic',
    name: 'Telefèric de Montjuïc',
    location: LatLng(41.3692, 2.1622),
    revealRadiusMeters: 800,
  ),
  // El punto más alto del Park Güell (las tres cruces): la entrada del park.
  Watchtower(
    id: 'atalaya_carmel',
    name: 'Turó de les Tres Creus',
    location: LatLng(41.4149, 2.1540),
  ),
  // El mirador clásico de la Sagrada Família (el estanque de la foto). Hoy
  // avista solo ese POI; la zona (Sant Pau, Monumental...) crecerá.
  Watchtower(
    id: 'atalaya_sagrada',
    name: 'Plaça de Gaudí',
    location: LatLng(41.4045, 2.1768),
  ),
  // El paseo del Arc de Triomf: Ciutadella y las tiendas otaku.
  Watchtower(
    id: 'atalaya_ciutadella',
    name: 'Passeig de Lluís Companys',
    location: LatLng(41.3897, 2.1845),
  ),
  // El gato de Botero en la Rambla del Raval: MACBA, CCCB, Bar Cañete y
  // Palau Güell.
  Watchtower(
    id: 'atalaya_raval',
    name: 'Gat del Raval',
    location: LatLng(41.3794, 2.1697),
  ),
  // La plaza del Tramvia Blau y el funicular del Tibidabo: CosmoCaixa y ABaC.
  Watchtower(
    id: 'atalaya_doctor_andreu',
    name: 'Plaça del Doctor Andreu',
    location: LatLng(41.4103, 2.1341),
  ),
  // El camino panorámico de Collserola a la altura de Bellesguard: la Torre.
  Watchtower(
    id: 'atalaya_aigues',
    name: 'Carretera de les Aigües',
    location: LatLng(41.4195, 2.1290),
  ),
  // El corazón de Gràcia: Casa Vicens.
  Watchtower(
    id: 'atalaya_gracia',
    name: 'Plaça del Sol',
    location: LatLng(41.4016, 2.1567),
  ),
  // El parque junto al Passeig Marítim: La Cova Fumada y la Enoteca.
  Watchtower(
    id: 'atalaya_barceloneta',
    name: 'Parc de la Barceloneta',
    location: LatLng(41.3818, 2.1937),
  ),
  // Esquerra de l'Eixample: Disfrutar y Cinc Sentits.
  Watchtower(
    id: 'atalaya_ninot',
    name: 'Mercat del Ninot',
    location: LatLng(41.3876, 2.1520),
  ),
  // La plaza de siempre del Poble-sec: Quimet & Quimet (y refuerza la Miró).
  Watchtower(
    id: 'atalaya_poblesec',
    name: 'Plaça del Sortidor',
    location: LatLng(41.3722, 2.1633),
  ),
];
