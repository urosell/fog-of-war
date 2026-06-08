// Servicio de localización: envuelve el plugin geolocator.
//
// Su trabajo es triple:
//  1) Asegurarse de que tenemos permiso de ubicación (pidiéndolo si hace falta),
//     incluido el permiso de segundo plano ("Todo el tiempo").
//  2) Dar un flujo (Stream) de posiciones que va emitiendo tu ubicación cada vez
//     que te mueves lo suficiente.
//  3) En Android, configurar un "servicio en primer plano" con notificación
//     permanente para que el sistema NO congele el seguimiento cuando la app
//     está cerrada o el móvil bloqueado.
//
// Aislar geolocator aquí (en vez de llamarlo por toda la app) hace que el resto
// del código no dependa de los detalles del plugin: si algún día cambiamos de
// librería de GPS, solo tocamos este archivo.

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resultado de pedir permiso de ubicación.
enum LocationPermissionResult {
  /// Permiso "Mientras usas la app" concedido: el GPS funciona con la app
  /// abierta, pero el seguimiento en segundo plano puede no ser fiable.
  grantedWhileInUse,

  /// Permiso "Todo el tiempo" concedido: seguimiento en segundo plano OK.
  grantedAlways,

  /// El usuario denegó el permiso (esta vez; se puede volver a pedir).
  denied,

  /// El usuario denegó "para siempre": hay que ir a Ajustes a mano.
  deniedForever,

  /// El GPS/ubicación del dispositivo está apagado a nivel de sistema.
  serviceDisabled,
}

class LocationService {
  /// Comprueba que el servicio de ubicación esté encendido y pide permiso si
  /// hace falta. Intenta conseguir el permiso de segundo plano ("Todo el
  /// tiempo"). Llamar antes de empezar a escuchar posiciones.
  Future<LocationPermissionResult> ensurePermission() async {
    // ¿Está encendida la ubicación a nivel de sistema (el interruptor del GPS)?
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return LocationPermissionResult.serviceDisabled;
    }

    // ¿Qué permiso tiene la app ahora mismo?
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      // Aún no se ha decidido: mostramos el diálogo del sistema. Android suele
      // conceder primero "Mientras usas la app".
      permiso = await Geolocator.requestPermission();
    }

    switch (permiso) {
      case LocationPermission.denied:
        return LocationPermissionResult.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionResult.deniedForever;
      case LocationPermission.always:
        return LocationPermissionResult.grantedAlways;
      case LocationPermission.whileInUse:
        return LocationPermissionResult.grantedWhileInUse;
      case LocationPermission.unableToDetermine:
        return LocationPermissionResult.denied;
    }
  }

  /// Flujo de posiciones. Emite una nueva ubicación cada vez que te mueves al
  /// menos [distanceFilterMeters] metros. En Android activa el servicio en
  /// primer plano (notificación permanente) para seguir registrando con la app
  /// cerrada. Convertimos la Position de geolocator a un LatLng de latlong2.
  Stream<LatLng> positionStream({int distanceFilterMeters = 10}) {
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        // Mantiene la CPU despierta para recibir posiciones con pantalla
        // apagada.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Fog of War',
          notificationText: 'Registrando tu recorrido para desvelar la niebla.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings)
        .map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  /// Lee una sola posición actual (útil para centrar el mapa al arrancar).
  Future<LatLng> currentPosition() async {
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }
}
