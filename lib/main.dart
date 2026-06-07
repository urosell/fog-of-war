// Fog of War — mapa con niebla.
//
// Muestra un mapa de OpenStreetMap cubierto por una niebla gris. Por ahora,
// para probar sin GPS, puedes desvelar la niebla tocando el mapa o con el botón
// (que desvela en el centro de la pantalla). El GPS real llegará en otro paso.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'fog/fog_controller.dart';
import 'fog/fog_layer.dart';

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
  // Centro inicial del mapa: Barcelona. Luego vendrá del GPS.
  static const LatLng _centroInicial = LatLng(41.3874, 2.1686);

  // Controla el estado del fog (celdas descubiertas).
  final FogController _fog = FogController();
  // Permite leer la posición/zoom actual del mapa (para el botón del centro).
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Cargar el fog guardado en disco (si lo hay) al arrancar.
    _fog.load();
  }

  @override
  void dispose() {
    _fog.dispose();
    super.dispose();
  }

  // Desvela la niebla alrededor de una coordenada.
  void _desvelar(LatLng punto) {
    _fog.reveal(punto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fog of War'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Contador de celdas descubiertas. ListenableBuilder se redibuja
          // cuando el fog cambia.
          ListenableBuilder(
            listenable: _fog,
            builder: (context, _) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_fog.discoveredCount} celdas'),
              ),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _centroInicial,
          initialZoom: 15,
          // Tocar el mapa desvela la niebla en ese punto (prueba sin GPS).
          onTap: (tapPosition, punto) => _desvelar(punto),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.fogofwar.fog_of_war',
          ),
          // La niebla va encima de los tiles del mapa.
          FogLayer(controller: _fog),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _desvelar(_mapController.camera.center),
        icon: const Icon(Icons.my_location),
        label: const Text('Desvelar centro'),
      ),
    );
  }
}
