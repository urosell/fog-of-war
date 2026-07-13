// Sesión del jugador: login con Google a través de Supabase Auth.
//
// El login abre el navegador (Custom Tab) con el OAuth de Google y vuelve a la
// app por el deep link fogofwar://login-callback (supabase_flutter captura la
// vuelta y guarda la sesión él solo, con refresco automático). Se eligió el
// flujo por navegador y no el nativo de google_sign_in a propósito: no exige
// registrar el SHA-1 de cada keystore (debug/release) en Google Cloud, solo un
// cliente OAuth web configurado una vez en el panel de Supabase.
//
// ChangeNotifier: la pantalla de Ajustes se redibuja sola al iniciar/cerrar
// sesión. Sin backend configurado (kCloudConfigured false), todo queda inerte.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_config.dart';

/// Llamar UNA vez antes de runApp. Sin configuración no hace nada (la app
/// sigue siendo 100% local). Si Supabase no responde al arrancar, tampoco
/// rompe el arranque: se queda sin nube hasta el próximo inicio.
Future<void> initCloud() async {
  if (!kCloudConfigured) return;
  try {
    await Supabase.initialize(
        url: kSupabaseUrl, publishableKey: kSupabasePublishableKey);
  } catch (e) {
    debugPrint('[cloud] init falló (seguimos en local): $e');
  }
}

class CloudAuth extends ChangeNotifier {
  StreamSubscription<AuthState>? _sub;
  bool _ready = false;

  CloudAuth() {
    if (!kCloudConfigured) return;
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
      _ready = true;
    } catch (e) {
      // Supabase.initialize falló al arrancar: sin nube esta sesión.
      debugPrint('[cloud] auth no disponible: $e');
    }
  }

  /// ¿Hay backend configurado Y operativo esta sesión?
  bool get isAvailable => _ready;

  Session? get _session =>
      _ready ? Supabase.instance.client.auth.currentSession : null;

  bool get isSignedIn => _session != null;

  /// Email de la cuenta (para mostrar en Ajustes), o null sin sesión.
  String? get email => _session?.user.email;

  /// Abre el navegador con el login de Google. La vuelta llega por el deep
  /// link y onAuthStateChange notifica. Devuelve false si no se pudo lanzar.
  Future<bool> signInWithGoogle() async {
    if (!_ready) return false;
    try {
      return await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kAuthRedirectUri,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('[cloud] login falló: $e');
      return false;
    }
  }

  /// Cierra la sesión. El progreso LOCAL se queda tal cual (local-first):
  /// solo deja de sincronizarse.
  Future<void> signOut() async {
    if (!_ready) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('[cloud] signOut falló: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
