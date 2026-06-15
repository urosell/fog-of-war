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
/// uno revele un buen puñado de POIs de su zona. Las coordenadas y el radio son
/// fáciles de ajustar tras probar en el terreno.
const List<Watchtower> kBarcelonaWatchtowers = [
  // Casco antiguo: Catedral, Picasso, Born (tapas), Palau Güell, Pl. Catalunya.
  Watchtower(
    id: 'atalaya_gotica',
    name: 'Atalaya Gòtica',
    location: LatLng(41.3839, 2.1762),
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
  // Montjuïc: Castell, Fundació Miró, MNAC.
  Watchtower(
    id: 'atalaya_montjuic',
    name: 'Atalaya de Montjuïc',
    location: LatLng(41.3667, 2.1656),
  ),
  // El Carmel: Park Güell y los Búnkers.
  Watchtower(
    id: 'atalaya_carmel',
    name: 'Atalaya del Carmel',
    location: LatLng(41.4165, 2.1575),
  ),
];
