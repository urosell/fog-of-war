// Test de RENDIMIENTO del mapa: mide frames (percentiles y % de jank) por
// estilo de mapa, con un guión de cámara fijo y determinista.
//
// NO es un test de aprobado/suspenso: produce datos. Se lanza con
// tool/perf/run_map_perf.ps1 (emulador, modo profile), que recoge el JSON del
// driver y pinta la tabla comparativa. Ejecutarlo en debug no vale: los
// números no son representativos y vector_map_tiles ignora `concurrency`.
//
// Por cada estilo (los 4 del juego y, si el binario lleva
// --dart-define=MAP_PERF_EXPERIMENTS=true, también las variantes de
// experimento) hace DOS pasadas del mismo guión:
//   • fría:     primer render de cada tile (cachés de ese theme vacías).
//   • caliente: mismo recorrido con los tiles ya en caché.
// El guión: pan continuo a z16 por el Eixample, barrido de zoom 16→14→18→16
// (cruza niveles enteros: el peor caso del render vectorial) y pan diagonal a
// zona nueva.

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_of_war/debug/frame_stats.dart';
import 'package:fog_of_war/main.dart';
import 'package:fog_of_war/map/map_style.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Filtro opcional de estilos a medir: csv de nameKeys
/// (p. ej. --dart-define=MAP_PERF_ONLY=game,satellite). Vacío = todos.
const String _only = String.fromEnvironment('MAP_PERF_ONLY');

// Recorrido por el Eixample, dentro de los límites de Barcelona (41.32-41.47 /
// 2.07-2.23) para que el CameraConstraint no recorte ningún movimiento.
const LatLng _inicio = LatLng(41.380, 2.140);
const double _zoomJuego = 16;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Frames reales del motor de forma continua, como en producción.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('mide frames por estilo de mapa', (tester) async {
    final resultados = <String, dynamic>{};
    final filtro = _only.isEmpty
        ? null
        : _only.split(',').map((s) => s.trim()).toSet();

    for (var i = 0; i < kActiveMapStyles.length; i++) {
      final estilo = kActiveMapStyles[i];
      if (filtro != null && !filtro.contains(estilo.nameKey)) continue;
      try {
        resultados[estilo.nameKey] = await _medirEstilo(tester, i, estilo);
      } catch (e) {
        resultados[estilo.nameKey] = {'error': '$e'};
      }
      // Guardado incremental: si un estilo posterior tirase el test, al menos
      // se conservan los ya medidos.
      binding.reportData = Map.of(resultados);
    }

    // Desmontar el último mapa DENTRO del test y dejar que los trabajos de
    // tiles pendientes se cancelen aquí: si se cancelan al cerrar el test,
    // vector_map_tiles suelta CancellationException sin dueño y el runner
    // marca el test como fallido "tras completarse".
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpDurante(tester, const Duration(seconds: 3));

    resultados['_meta'] = {
      'experiments': kMapPerfExperiments,
      'timestamp': DateTime.now().toIso8601String(),
    };
    binding.reportData = resultados;
  }, timeout: const Timeout(Duration(minutes: 30)));
}

Future<Map<String, dynamic>> _medirEstilo(
    WidgetTester tester, int styleIndex, MapStyle estilo) async {
  // App nueva por estilo: capa y cachés de memoria parten de cero (las de
  // disco solo si el script hizo `pm clear`, que es lo que hace entre runs).
  // La key única por estilo importa: sin ella Flutter REUTILIZA el estado del
  // MapScreen anterior (mismo tipo, misma posición) y ni el MapController
  // nuevo ni el estilo inicial llegan a aplicarse.
  final mapController = MapController();
  await tester.pumpWidget(FogOfWarApp(
    key: ValueKey('perf_$styleIndex'),
    mapController: mapController,
    initialStyleIndex: styleIndex,
    skipOnboarding: true,
  ));

  // Esperar a que la capa base esté montada (el estilo vectorial se descarga
  // asíncrono; si falla, la app cae a raster y esto expira → error).
  final capa = estilo.isVector
      ? find.byType(VectorTileLayer)
      : find.byType(TileLayer);
  await _pumpHasta(tester, () => capa.evaluate().isNotEmpty,
      const Duration(seconds: 20), 'capa base de ${estilo.nameKey}');

  // Un arrastre corto = gesto de usuario: desactiva el auto-seguir para que
  // un fix de GPS tardío no nos pelee la cámara durante el guión.
  await tester.drag(find.byType(FlutterMap), const Offset(0, -60));
  await tester.pump();

  // Al punto de partida, y un respiro para que asiente el arranque (contenido,
  // primer fix de GPS…) antes de empezar a medir.
  mapController.move(_inicio, _zoomJuego);
  await _pumpDurante(tester, const Duration(seconds: 3));

  // Pasada FRÍA: el primer render de los tiles del recorrido cae dentro de la
  // ventana medida (es el coste que da tirones al explorar zona nueva).
  final fria = await _guionDeCamara(tester, mapController);

  // Pasada CALIENTE: mismo recorrido con los tiles ya renderizados en caché.
  mapController.move(_inicio, _zoomJuego);
  await _pumpDurante(tester, const Duration(seconds: 2));
  final caliente = await _guionDeCamara(tester, mapController);

  // Drenaje: cámara quieta un par de segundos para que no queden renders de
  // tile en vuelo cuando el siguiente pumpWidget desmonte este mapa (las
  // cancelaciones en pleno vuelo acaban en excepciones sin dueño).
  await _pumpDurante(tester, const Duration(seconds: 2));

  return {'cold': fria.toJson(), 'warm': caliente.toJson()};
}

/// El guión de cámara medido: pan continuo, barrido de zoom y pan diagonal.
Future<FrameStatsReport> _guionDeCamara(
    WidgetTester tester, MapController c) async {
  final collector = FrameStatsCollector()..start();
  var pos = _inicio;

  // (a) Pan continuo hacia el este (~1 km) y luego norte (~660 m) a z16, como
  // quien camina/arrastra: un paso pequeño por frame.
  pos = await _pan(tester, c, pos, const LatLng(41.380, 2.152), 360);
  pos = await _pan(tester, c, pos, const LatLng(41.386, 2.152), 240);

  // (b) Barrido de zoom cruzando niveles enteros (re-render en cada nivel).
  await _zoom(tester, c, pos, de: 16, a: 14, pasos: 120);
  await _pumpDurante(tester, const Duration(milliseconds: 500));
  await _zoom(tester, c, pos, de: 14, a: 18, pasos: 240);
  await _pumpDurante(tester, const Duration(milliseconds: 500));
  await _zoom(tester, c, pos, de: 18, a: 16, pasos: 120);

  // (c) Pan diagonal a zona nueva (suroeste, ~1.2 km).
  await _pan(tester, c, pos, const LatLng(41.376, 2.128), 300);

  return collector.stop();
}

/// Mueve la cámara de [desde] a [hasta] en [pasos] frames a zoom fijo.
Future<LatLng> _pan(WidgetTester tester, MapController c, LatLng desde,
    LatLng hasta, int pasos) async {
  for (var i = 1; i <= pasos; i++) {
    final t = i / pasos;
    final p = LatLng(
      desde.latitude + (hasta.latitude - desde.latitude) * t,
      desde.longitude + (hasta.longitude - desde.longitude) * t,
    );
    c.move(p, _zoomJuego);
    await tester.pump();
  }
  return hasta;
}

/// Zoom continuo de [de] a [a] en [pasos] frames, centrado en [centro].
Future<void> _zoom(WidgetTester tester, MapController c, LatLng centro,
    {required double de, required double a, required int pasos}) async {
  for (var i = 1; i <= pasos; i++) {
    c.move(centro, de + (a - de) * i / pasos);
    await tester.pump();
  }
}

/// Bombea frames durante [duracion] de tiempo real (deja avanzar cargas).
Future<void> _pumpDurante(WidgetTester tester, Duration duracion) async {
  final reloj = Stopwatch()..start();
  while (reloj.elapsed < duracion) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Bombea frames hasta que [listo] sea cierto o expire [limite].
Future<void> _pumpHasta(WidgetTester tester, bool Function() listo,
    Duration limite, String que) async {
  final reloj = Stopwatch()..start();
  while (!listo()) {
    if (reloj.elapsed > limite) {
      throw TimeoutException('esperando $que', limite);
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class TimeoutException implements Exception {
  final String mensaje;
  final Duration limite;
  TimeoutException(this.mensaje, this.limite);

  @override
  String toString() => 'Timeout (${limite.inSeconds}s) $mensaje';
}
