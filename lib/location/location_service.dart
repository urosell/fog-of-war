// Servicio de localización: envuelve el plugin geolocator.
//
// Su trabajo es doble:
//  1) Asegurarse de que tenemos permiso de ubicación (pidiéndolo si hace falta).
//  2) Dar un flujo (Stream) de posiciones que va emitiendo tu ubicación cada vez
//     que te mueves lo suficiente.
//
// Aislar geolocator aquí (en vez de llamarlo por toda la app) hace que el resto
// del código no dependa de los detalles del plugin: si algún día cambiamos de
// librería de GPS, solo tocamos este archivo.

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resultado de pedir permiso de ubicación.
enum LocationPermissionResult {
  /// Permiso concedido y servicio de ubicación activo: todo listo.
  granted,

  /// El usuario denegó el permiso (esta vez; se puede volver a pedir).
  denied,

  /// El usuario denegó "para siempre": hay que ir a Ajustes a mano.
  deniedForever,

  /// El GPS/ubicación del dispositivo está apagado a nivel de sistema.
  serviceDisabled,
}

class LocationService {
  /// Comprueba que el servicio de ubicación esté encendido y pide permiso si
  /// hace falta. Llamar antes de empezar a escuchar posiciones.
  Future<LocationPermissionResult> ensurePermission() async {
    // ¿Está encendida la ubicación a nivel de sistema (el interruptor del GPS)?
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return LocationPermissionResult.serviceDisabled;
    }

    // ¿Qué permiso tiene la app ahora mismo?
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      // Aún no se ha decidido: mostramos el diálogo del sistema.
      permiso = await Geolocator.requestPermission();
    }

    switch (permiso) {
      case LocationPermission.denied:
        return LocationPermissionResult.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionResult.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionResult.granted;
      case LocationPermission.unableToDetermine:
        return LocationPermissionResult.denied;
    }
  }

  /// Flujo de posiciones. Emite una nueva ubicación cada vez que te mueves al
  /// menos [distanceFilterMeters] metros. Convertimos la Position de geolocator
  /// a un LatLng de latlong2, que es lo que usa el resto de la app.
  Stream<LatLng> positionStream({int distanceFilterMeters = 10}) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  /// Lee una sola posición actual (útil para centrar el mapa al arrancar).
  Future<LatLng> currentPosition() async {
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }
}
