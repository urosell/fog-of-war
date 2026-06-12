// Definición de una "ciudad" y cálculo del porcentaje de descubrimiento.
//
// Una ciudad es, de momento, una caja geográfica (bounding box): cuatro límites
// sur/oeste/norte/este. Con esa caja sabemos qué celdas del grid Z20 caen dentro
// y, por tanto, cuántas hay en total y cuántas has desvelado.
//
// Limitación conocida (MVP): la caja cuenta TODAS las celdas, incluido mar,
// montaña o zonas a las que nadie va. El blueprint prevé contar solo "celdas de
// tierra" en el futuro (dato del servidor). Por eso ahora el % de una ciudad
// entera sale pequeño: es honesto, una ciudad es muchísimo terreno.

import 'package:latlong2/latlong.dart';

import '../fog/tile_math.dart';

/// Una ciudad delimitada por una caja geográfica.
class City {
  final String id;
  final String name;

  // Límites de la caja, en grados.
  final double south; // latitud mínima
  final double west; // longitud mínima
  final double north; // latitud máxima
  final double east; // longitud máxima

  const City({
    required this.id,
    required this.name,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  // --- Rango de celdas Z20 que cubre la ciudad ---
  //
  // En el sistema de celdas: x crece hacia el este, y crece hacia el sur.
  // Por eso la esquina noroeste (norte, oeste) da el (x, y) mínimo y la esquina
  // sureste (sur, este) da el (x, y) máximo.

  CellId get _northWestCell => cellForLatLng(LatLng(north, west));
  CellId get _southEastCell => cellForLatLng(LatLng(south, east));

  int get _xMin => _northWestCell.x;
  int get _yMin => _northWestCell.y;
  int get _xMax => _southEastCell.x;
  int get _yMax => _southEastCell.y;

  /// Número total de celdas Z20 que caben dentro de la caja de la ciudad.
  int get totalCells => (_xMax - _xMin + 1) * (_yMax - _yMin + 1);

  /// ¿Cae esta celda dentro de los límites de la ciudad?
  bool containsCell(CellId cell) =>
      cell.x >= _xMin &&
      cell.x <= _xMax &&
      cell.y >= _yMin &&
      cell.y <= _yMax;

  /// Cuántas de las celdas [discovered] caen dentro de la ciudad.
  int discoveredCount(Set<CellId> discovered) {
    var count = 0;
    for (final cell in discovered) {
      if (containsCell(cell)) count++;
    }
    return count;
  }

  /// Porcentaje (0..100) de la ciudad que se ha desvelado.
  double discoveryPercentage(Set<CellId> discovered) {
    final total = totalCells;
    if (total == 0) return 0;
    return discoveredCount(discovered) / total * 100.0;
  }

  /// Centro geográfico de la caja (para centrar el mapa en la ciudad).
  LatLng get center => LatLng((south + north) / 2, (west + east) / 2);

  /// ¿Cae esta coordenada dentro de la caja de la ciudad? (para contar POIs).
  bool containsLatLng(LatLng p) =>
      p.latitude >= south &&
      p.latitude <= north &&
      p.longitude >= west &&
      p.longitude <= east;
}

/// Barcelona, con límites aproximados del término municipal y alrededores.
const City kBarcelona = City(
  id: 'barcelona_es',
  name: 'Barcelona',
  south: 41.32,
  west: 2.07,
  north: 41.47,
  east: 2.23,
);

/// Todas las ciudades jugables. De momento solo Barcelona tiene POIs; el resto
/// se incluyen para ver el progreso de exploración (celdas desveladas) y se irán
/// poblando de POIs más adelante. Los límites son cajas aproximadas.
const List<City> kCities = [
  kBarcelona,
  City(
    id: 'madrid_es',
    name: 'Madrid',
    south: 40.31, west: -3.83, north: 40.51, east: -3.55,
  ),
  City(
    id: 'valencia_es',
    name: 'València',
    south: 39.42, west: -0.42, north: 39.52, east: -0.30,
  ),
  City(
    id: 'sevilla_es',
    name: 'Sevilla',
    south: 37.32, west: -6.04, north: 37.43, east: -5.92,
  ),
  City(
    id: 'girona_es',
    name: 'Girona',
    south: 41.95, west: 2.79, north: 42.01, east: 2.86,
  ),
  City(
    id: 'paris_fr',
    name: 'París',
    south: 48.815, west: 2.224, north: 48.902, east: 2.469,
  ),
];
