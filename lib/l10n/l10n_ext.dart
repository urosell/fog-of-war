// Atajo para acceder a las traducciones: context.l10n.miClave
// en vez de AppLocalizations.of(context)!.miClave.

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
