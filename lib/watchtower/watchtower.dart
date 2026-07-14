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

/// Atalayas jugables de Barcelona: miradores icónicos colocados para que cada
/// uno revele un buen puñado de POIs de su zona. Las coordenadas y el radio
/// están verificados con `dart run tool/watchtower_coverage.dart` (qué avista
/// cada una y qué POIs quedan huérfanos); el círculo del modo admin enseña el
/// rango sobre el mapa. Único POI sin cubrir a propósito: el Tibidabo, que ya
/// es un mirador en sí mismo.
const List<Watchtower> kBarcelonaWatchtowers = [
  // Casco antiguo: Catedral, Picasso, Born (tapas), Palau Güell. Radio 650
  // para llegar también a Pl. Catalunya (a ~620 m de la Catedral).
  Watchtower(
    id: 'atalaya_gotica',
    name: 'Atalaya Gòtica',
    location: LatLng(41.3839, 2.1762),
    revealRadiusMeters: 650,
  ),
  // Eixample: Casa Batlló, La Pedrera, Lasarte y compañía.
  Watchtower(
    id: 'atalaya_eixample',
    name: "Atalaya de l'Eixample",
    location: LatLng(41.3940, 2.1635),
  ),
  // Port / Rambla: Mirador de Colom, Museu Marítim, Palau Güell.
  Watchtower(
    id: 'atalaya_port',
    name: 'Atalaya del Port',
    location: LatLng(41.3759, 2.1774),
  ),
  // Montjuïc, ladera del Migdia: Castell, MNAC y Fundació Miró (en el castillo
  // no se llegaba al MNAC). Radio 700: la montaña es grande y el castillo
  // queda a ~640 m; como mirador amplio que es, lo justifica.
  Watchtower(
    id: 'atalaya_montjuic',
    name: 'Atalaya de Montjuïc',
    location: LatLng(41.3660, 2.1590),
    revealRadiusMeters: 700,
  ),
  // El Carmel: Park Güell y los Búnkers.
  Watchtower(
    id: 'atalaya_carmel',
    name: 'Atalaya del Carmel',
    location: LatLng(41.4165, 2.1575),
  ),
  // Plaça de Gaudí, el mirador clásico de la Sagrada Família. Hoy avista solo
  // ese POI; la zona (Sant Pau, Monumental...) crecerá con el contenido.
  Watchtower(
    id: 'atalaya_sagrada',
    name: 'Atalaya de la Sagrada Família',
    location: LatLng(41.4045, 2.1768),
  ),
  // Passeig de Lluís Companys: Arc de Triomf, Ciutadella y las tiendas otaku.
  Watchtower(
    id: 'atalaya_ciutadella',
    name: 'Atalaya de la Ciutadella',
    location: LatLng(41.3897, 2.1845),
  ),
  // Rambla del Raval: MACBA, CCCB, Bar Cañete y Palau Güell.
  Watchtower(
    id: 'atalaya_raval',
    name: 'Atalaya del Raval',
    location: LatLng(41.3796, 2.1698),
  ),
  // Pie de la Av. Tibidabo / Bellesguard: Torre Bellesguard, CosmoCaixa, ABaC.
  Watchtower(
    id: 'atalaya_bellesguard',
    name: 'Atalaya de Bellesguard',
    location: LatLng(41.4135, 2.1327),
  ),
  // Gràcia alta (Travessera de Dalt): Casa Vicens y la entrada del Park Güell.
  // Radio 700: los dos quedan a ~600 m en direcciones opuestas.
  Watchtower(
    id: 'atalaya_gracia',
    name: 'Atalaya de Gràcia',
    location: LatLng(41.4090, 2.1522),
    revealRadiusMeters: 700,
  ),
  // Passeig Marítim de la Barceloneta: La Cova Fumada y la Enoteca.
  Watchtower(
    id: 'atalaya_barceloneta',
    name: 'Atalaya de la Barceloneta',
    location: LatLng(41.3823, 2.1926),
  ),
  // Esquerra de l'Eixample (Mercat del Ninot): Disfrutar y Cinc Sentits.
  Watchtower(
    id: 'atalaya_ninot',
    name: 'Atalaya del Ninot',
    location: LatLng(41.3876, 2.1520),
  ),
  // Poble-sec (Plaça del Sortidor): Quimet & Quimet (y refuerza la Miró).
  Watchtower(
    id: 'atalaya_poblesec',
    name: 'Atalaya del Poble-sec',
    location: LatLng(41.3722, 2.1633),
  ),
];
