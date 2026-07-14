// Cobertura de las atalayas sobre el pozo de POIs (herramienta de contenido).
//
// Uso: dart run tool/watchtower_coverage.dart
//
// Para cada atalaya lista qué POIs del pozo (kBarcelonaPois, la semilla que
// refleja la hoja) caen dentro de su radio de avistado, con la distancia; y al
// final, los POIs que NINGUNA atalaya cubre. Sirve para colocar atalayas
// nuevas y ajustar radios sin ir a ciegas (el círculo del modo admin enseña
// lo mismo sobre el mapa, esto da los números).

// ignore_for_file: avoid_print  (herramienta de consola: imprimir es su trabajo)

import 'package:fog_of_war/poi/poi.dart';
import 'package:fog_of_war/watchtower/watchtower.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const distance = Distance();
  final cubiertos = <String>{};

  for (final tower in kBarcelonaWatchtowers) {
    final avistados = <(Poi, double)>[
      for (final poi in kBarcelonaPois)
        if (distance(tower.location, poi.location) <= tower.revealRadiusMeters)
          (poi, distance(tower.location, poi.location).toDouble()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    print('${tower.name} (${tower.revealRadiusMeters.round()} m): '
        '${avistados.length} POIs');
    for (final (poi, metros) in avistados) {
      cubiertos.add(poi.id);
      print('   ${metros.round().toString().padLeft(4)} m  ${poi.id}');
    }
  }

  final huerfanos =
      kBarcelonaPois.where((p) => !cubiertos.contains(p.id)).toList();
  print('\nSin cubrir por ninguna atalaya: ${huerfanos.length}');
  for (final poi in huerfanos) {
    print('   ${poi.id} (${poi.category.label})');
  }
}
