// Estado del idioma de la app.
//
// Mantiene el Locale elegido (o null = seguir el idioma del sistema), lo carga
// del disco al arrancar y lo persiste al cambiarlo. Al ser un ChangeNotifier,
// MaterialApp se reconstruye y toda la app cambia de idioma al instante.

import 'package:flutter/material.dart';

import 'locale_storage.dart';

class LocaleController extends ChangeNotifier {
  final LocaleStorage _storage;

  Locale? _locale;

  LocaleController([LocaleStorage? storage]) : _storage = storage ?? LocaleStorage();

  /// Idioma forzado por el usuario, o null si se sigue el del sistema.
  Locale? get locale => _locale;

  /// Carga la preferencia guardada (si la hay).
  Future<void> load() async {
    final code = await _storage.load();
    if (code == null) return;
    _locale = Locale(code);
    notifyListeners();
  }

  /// Fija el idioma (null = volver al idioma del sistema) y lo guarda.
  void setLocale(Locale? locale) {
    if (locale?.languageCode == _locale?.languageCode) return;
    _locale = locale;
    notifyListeners();
    _storage.save(locale?.languageCode);
  }
}
