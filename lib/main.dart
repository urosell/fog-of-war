// Fog of War — mapa con niebla que se desvela al moverte (GPS).
//
// Al arrancar pide permiso de ubicación y, si lo concedes, escucha tu posición:
// cada vez que te mueves, pinta tu posición, centra el mapa en ti y desvela la
// niebla a tu alrededor. Como respaldo (y para pruebas sin GPS), también puedes
// desvelar tocando el mapa.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'cities/city.dart';
import 'fog/fog_controller.dart';
import 'fog/fog_layer.dart';
import 'location/location_service.dart';

void main() {
  runApp(const FogOfWarApp());
}

class FogOfWarApp extends StatelessWidget {
  const FogOfWarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fog of War',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Centro inicial del mapa mientras aún no tenemos posición GPS: Barcelona.
  static const LatLng _centroInicial = LatLng(41.3874, 2.1686);

  // Controla el estado del fog (celdas descubiertas).
  final FogController _fog = FogController();
  // Permite mover/leer la cámara del mapa (para centrar en el usuario).
  final MapController _mapController = MapController();
  // Acceso al GPS.
  final LocationService _location = LocationService();

  // Suscripción al flujo de posiciones; se cancela al cerrar la pantalla.
  StreamSubscription<LatLng>? _posSub;
  // Última posición conocida del usuario (null hasta la primera lectura).
  LatLng? _userPosition;
  // Si está activo, el mapa sigue automáticamente al usuario al moverse.
  bool _seguir = true;

  @override
  void initState() {
    super.initState();
    // Cargar el fog guardado en disco (si lo hay) y luego arrancar el GPS.
    _fog.load();
    _iniciarGps();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _fog.dispose();
    super.dispose();
  }

  // Pide permiso y, si se concede, empieza a escuchar la posición.
  Future<void> _iniciarGps() async {
    final resultado = await _location.ensurePermission();
    if (!mounted) return;

    final concedido = resultado == LocationPermissionResult.grantedAlways ||
        resultado == LocationPermissionResult.grantedWhileInUse;
    if (!concedido) {
      _mostrarAviso(_mensajePermiso(resultado));
      return;
    }

    // Con "Mientras usas la app" el GPS funciona, pero el segundo plano puede
    // no ser fiable: avisamos para que el usuario suba el permiso a Ajustes.
    if (resultado == LocationPermissionResult.grantedWhileInUse) {
      _mostrarAviso(
          'Para registrar con la app cerrada, pon "Permitir todo el tiempo" '
          'en Ajustes de ubicación.');
    }

    _posSub = _location.positionStream().listen(_onNuevaPosicion);
  }

  // Se ejecuta cada vez que el GPS nos da una posición nueva.
  void _onNuevaPosicion(LatLng pos) {
    setState(() => _userPosition = pos);
    // Desvelar la niebla a tu alrededor.
    _fog.reveal(pos);
    // Si el modo "seguir" está activo, centrar el mapa en ti.
    if (_seguir) {
      _mapController.move(pos, _mapController.camera.zoom);
    }
  }

  // Mensaje legible según por qué no tenemos permiso/GPS.
  String _mensajePermiso(LocationPermissionResult r) {
    switch (r) {
      case LocationPermissionResult.serviceDisabled:
        return 'La ubicación del dispositivo está apagada. Actívala para jugar.';
      case LocationPermissionResult.deniedForever:
        return 'Permiso de ubicación denegado. Actívalo en Ajustes de la app.';
      case LocationPermissionResult.denied:
        return 'Sin permiso de ubicación: la niebla no se desvelará al moverte.';
      case LocationPermissionResult.grantedWhileInUse:
      case LocationPermissionResult.grantedAlways:
        return '';
    }
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fog of War'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Progreso: % de la ciudad desvelado + celdas totales.
          // ListenableBuilder se redibuja cuando el fog cambia.
          ListenableBuilder(
            listenable: _fog,
            builder: (context, _) {
              final pct = kBarcelona.discoveryPercentage(_fog.discovered);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${kBarcelona.name} '
                    '${pct.toStringAsFixed(2)}% · ${_fog.discoveredCount} celdas',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userPosition ?? _centroInicial,
          initialZoom: 16,
          // Si el usuario arrastra el mapa a mano, desactivamos el auto-seguir
          // para no pelearnos con él.
          onPositionChanged: (camera, hasGesture) {
            if (hasGesture && _seguir) {
              setState(() => _seguir = false);
            }
          },
          // Tocar el mapa desvela la niebla en ese punto (respaldo / pruebas).
          onTap: (tapPosition, punto) => _fog.reveal(punto),
        ),
        children: [
          // Mapa base con estilo oscuro (Carto "Dark Matter"). Sobre este fondo
          // oscuro, la niebla y las zonas desveladas resaltan mucho mejor.
          // Carto sirve los tiles desde varios subdominios (a/b/c/d) para
          // repartir la carga. Atribución obligatoria: © OpenStreetMap, © CARTO.
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.fogofwar.fog_of_war',
          ),
          // La niebla va encima de los tiles del mapa.
          FogLayer(controller: _fog),
          // Punto azul de "estás aquí" (solo si ya tenemos posición).
          if (_userPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _userPosition!,
                  width: 24,
                  height: 24,
                  child: const _MarcadorUsuario(),
                ),
              ],
            ),
        ],
      ),
      // Botón para volver a centrar el mapa en ti y reactivar el auto-seguir.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final pos = _userPosition;
          if (pos == null) {
            _mostrarAviso('Aún no tengo tu ubicación.');
            return;
          }
          setState(() => _seguir = true);
          _mapController.move(pos, _mapController.camera.zoom);
        },
        child: Icon(_seguir ? Icons.my_location : Icons.location_searching),
      ),
    );
  }
}

// Dibujo del marcador de posición del usuario: un punto azul con borde blanco.
class _MarcadorUsuario extends StatelessWidget {
  const _MarcadorUsuario();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4),
        ],
      ),
    );
  }
}
