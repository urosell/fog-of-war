// Notificaciones locales del sistema.
//
// Su único cometido es avisar al usuario con una notificación del móvil cuando
// pasa algo que merece la pena (descubrir un POI) mientras la app está
// MINIMIZADA. Con la app abierta usamos el toast de cristal (ui/toast.dart); en
// segundo plano el toast no se ve, así que recurrimos a la bandeja del sistema.
//
// La detección de POIs sigue corriendo en segundo plano gracias al servicio en
// primer plano del GPS (ver location_service.dart), así que solo nos falta
// "pintar" el aviso.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Canal de Android para los avisos de descubrimiento. Importancia alta para
  // que aparezca como aviso emergente ("heads-up") y con sonido.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'discoveries',
    'Descubrimientos',
    description: 'Avisos al descubrir un punto de interés.',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Inicializa el plugin y crea el canal de Android. Idempotente.
  ///
  /// Envuelto en try/catch: en entornos sin plataforma de notificaciones
  /// (tests, web sin soporte) las llamadas al plugin fallan, y un fallo de
  /// notificaciones NUNCA debe tumbar la app.
  Future<void> init() async {
    if (_initialized) return;
    try {
      // Icono pequeño monocromo (res/drawable/ic_notification.xml). NO el
      // ic_launcher a color, que Android pintaría como un cuadro blanco.
      const android = AndroidInitializationSettings('ic_notification');
      const ios = DarwinInitializationSettings(
        // El permiso lo pedimos aparte en requestPermission().
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );

      // Crear el canal por adelantado (en Android 8+).
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] init falló: $e');
    }
  }

  /// Pide permiso para mostrar notificaciones (Android 13+ e iOS lo exigen).
  Future<void> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] requestPermission falló: $e');
    }
  }

  /// Muestra una notificación de descubrimiento. [id] permite que varios avisos
  /// seguidos no se pisen (o usa el mismo id para reemplazar).
  Future<void> showDiscovery({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (!_initialized) await init();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          // Color de acento del icono/cabecera (turquesa del juego).
          color: const Color(0xFF1FB8C4),
          // Resumen visible si llegan varias.
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] showDiscovery falló: $e');
    }
  }
}
