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

/// Modo de seguimiento del GPS. Cada uno equilibra precisión y batería.
enum TrackingMode {
  /// Alta precisión y refresco frecuente. Para salir a descubrir activamente.
  /// Gasta más batería (como una app de running).
  exploracion,

  /// Precisión media y refresco espaciado. Para llevar la app puesta en el día
  /// a día sin vaciar la batería.
  ahorro,
}

/// Ajustes concretos de GPS para cada modo.
class _ModeConfig {
  final LocationAccuracy accuracy;
  final int distanceFilterMeters;
  final Duration interval;
  final String notificationText;

  const _ModeConfig({
    required this.accuracy,
    required this.distanceFilterMeters,
    required this.interval,
    required this.notificationText,
  });
}

_ModeConfig _configFor(TrackingMode mode) {
  switch (mode) {
    case TrackingMode.exploracion:
      return const _ModeConfig(
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 10,
        interval: Duration(seconds: 4),
        notificationText: 'Explorando con alta precisión.',
      );
    case TrackingMode.ahorro:
      return const _ModeConfig(
        accuracy: LocationAccuracy.medium,
        distanceFilterMeters: 40,
        interval: Duration(seconds: 30),
        notificationText: 'Modo ahorro de batería.',
      );
  }
}

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

  /// Flujo de posiciones según el [mode] elegido (precisión vs batería). Emite
  /// una nueva ubicación cada vez que te mueves lo suficiente. En Android activa
  /// el servicio en primer plano (notificación permanente) para seguir
  /// registrando con la app cerrada. Convertimos la Position de geolocator a un
  /// LatLng de latlong2.
  Stream<LatLng> positionStream({TrackingMode mode = TrackingMode.exploracion}) {
    final cfg = _configFor(mode);
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: cfg.accuracy,
        distanceFilter: cfg.distanceFilterMeters,
        // Intervalo mínimo entre lecturas: más largo en modo ahorro.
        intervalDuration: cfg.interval,
        // Mantiene la CPU despierta para recibir posiciones con pantalla
        // apagada. El texto cambia según el modo para que el usuario lo vea.
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Fog of War',
          notificationText: cfg.notificationText,
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      settings = LocationSettings(
        accuracy: cfg.accuracy,
        distanceFilter: cfg.distanceFilterMeters,
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
