// Pantalla de Ajustes: por ahora, personalizar el marcador del jugador.
//
// Muestra un preview grande del marcador y dos secciones para elegir icono y
// color. Los cambios se aplican y guardan al instante (el AvatarController
// notifica, así que el preview y el mapa se actualizan en vivo).

import 'package:flutter/material.dart';

import '../avatar/avatar.dart';
import '../avatar/avatar_controller.dart';
import '../cloud/cloud_auth.dart';
import '../cloud/cloud_sync.dart';
import '../l10n/l10n_ext.dart';
import '../locale/locale_controller.dart';
import 'hud.dart' show kHudAccent;

/// Fondo oscuro, en sintonía con el tono de la niebla (igual que las demás
/// pantallas de la app).
const Color _kBackground = Color(0xFF161A21);

/// Idiomas que ofrece el selector. `code` null = seguir el idioma del sistema;
/// `name` se muestra en su propio idioma (endónimo) para reconocerlo siempre.
class _LangOption {
  final String? code;
  final String name;
  const _LangOption(this.code, this.name);
}

const List<_LangOption> _kLanguages = [
  _LangOption('es', 'Español'),
  _LangOption('en', 'English'),
  _LangOption('ca', 'Català'),
  _LangOption('fr', 'Français'),
];

class SettingsScreen extends StatelessWidget {
  final AvatarController avatar;
  final LocaleController localeController;
  // Cuenta y sync en la nube. Nulos (o sin backend configurado) = la sección
  // de cuenta no se muestra y la pantalla queda como siempre.
  final CloudAuth? cloudAuth;
  final CloudSync? cloudSync;

  const SettingsScreen({
    super.key,
    required this.avatar,
    required this.localeController,
    this.cloudAuth,
    this.cloudSync,
  });

  @override
  Widget build(BuildContext context) {
    final auth = cloudAuth;
    final mostrarCuenta = auth != null && auth.isAvailable;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.settingsTitle),
      ),
      // Escucha avatar + idioma (+ cuenta/sync si hay): al cambiar cualquiera,
      // se redibuja (y al cambiar el idioma, MaterialApp reconstruye todo).
      body: ListenableBuilder(
        listenable: Listenable.merge([
          avatar,
          localeController,
          if (mostrarCuenta) auth,
          ?cloudSync,
        ]),
        builder: (context, _) {
          final l = context.l10n;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (mostrarCuenta) ...[
                _SectionTitle(l.settingsAccount),
                const SizedBox(height: 12),
                _AccountCard(auth: auth, sync: cloudSync),
                const SizedBox(height: 28),
              ],
              _PreviewCard(icon: avatar.icon, color: avatar.color),
              const SizedBox(height: 28),
              _SectionTitle(l.settingsIcon),
              const SizedBox(height: 12),
              _IconPicker(
                selected: avatar.iconIndex,
                color: avatar.color,
                onPick: avatar.setIcon,
              ),
              const SizedBox(height: 28),
              _SectionTitle(l.settingsColor),
              const SizedBox(height: 12),
              _ColorPicker(
                selected: avatar.colorIndex,
                onPick: avatar.setColor,
              ),
              const SizedBox(height: 28),
              _SectionTitle(l.settingsLanguage),
              const SizedBox(height: 12),
              _LanguagePicker(
                current: localeController.locale?.languageCode,
                systemLabel: l.languageSystem,
                onPick: (code) => localeController
                    .setLocale(code == null ? null : Locale(code)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta de cuenta: sin sesión, explica el beneficio y ofrece el login con
/// Google; con sesión, muestra el email, el estado del sync y cerrar sesión.
class _AccountCard extends StatelessWidget {
  final CloudAuth auth;
  final CloudSync? sync;

  const _AccountCard({required this.auth, required this.sync});

  Future<void> _login(BuildContext context) async {
    final l = context.l10n;
    final abierto = await auth.signInWithGoogle();
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.accountSignInFailed)));
    }
  }

  // Línea de estado del sync bajo el email.
  (IconData, String, Color) _estado(BuildContext context) {
    final l = context.l10n;
    return switch (sync?.status) {
      CloudSyncStatus.syncing => (Icons.sync, l.accountSyncing, Colors.white70),
      CloudSyncStatus.error =>
        (Icons.cloud_off, l.accountSyncError, Colors.orangeAccent),
      _ => (Icons.cloud_done, l.accountSynced, kHudAccent),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: !auth.isSignedIn
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.accountBenefit,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _login(context),
                  icon: const Icon(Icons.login),
                  label: Text(l.accountSignIn),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            )
          : Builder(builder: (context) {
              final (icono, texto, color) = _estado(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle,
                          color: Colors.white70, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.email ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(icono, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(texto, style: TextStyle(color: color, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: auth.signOut,
                      child: Text(
                        l.accountSignOut,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ],
              );
            }),
    );
  }
}

/// Tarjeta superior con el marcador a tamaño grande sobre un fondo suave.
class _PreviewCard extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PreviewCard({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.black.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarMarker(icon: icon, color: color, size: 72),
          const SizedBox(height: 14),
          Text(
            context.l10n.settingsMarkerPreview,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Fila de iconos elegibles. El seleccionado se resalta con el color actual.
class _IconPicker extends StatelessWidget {
  final int selected;
  final Color color;
  final ValueChanged<int> onPick;

  const _IconPicker({
    required this.selected,
    required this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < kAvatarIcons.length; i++)
          _IconTile(
            icon: kAvatarIcons[i],
            selected: i == selected,
            accent: color,
            onTap: () => onPick(i),
          ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _IconTile({
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? accent : Colors.white.withValues(alpha: 0.8),
          size: 28,
        ),
      ),
    );
  }
}

/// Rejilla de muestras de color. La seleccionada lleva un anillo blanco.
class _ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onPick;

  const _ColorPicker({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (var i = 0; i < kAvatarColors.length; i++)
          _ColorTile(
            color: kAvatarColors[i],
            selected: i == selected,
            onTap: () => onPick(i),
          ),
      ],
    );
  }
}

class _ColorTile extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 12)]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

/// Selector de idioma: una opción "del sistema" + un idioma por cada uno
/// soportado. [current] es el código forzado (null = sistema).
class _LanguagePicker extends StatelessWidget {
  final String? current;
  final String systemLabel;
  final ValueChanged<String?> onPick;

  const _LanguagePicker({
    required this.current,
    required this.systemLabel,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LanguageRow(
          label: systemLabel,
          icon: Icons.smartphone,
          selected: current == null,
          onTap: () => onPick(null),
        ),
        for (final lang in _kLanguages)
          _LanguageRow(
            label: lang.name,
            selected: current == lang.code,
            onTap: () => onPick(lang.code),
          ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? kHudAccent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kHudAccent : Colors.white.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20,
                  color: selected
                      ? kHudAccent
                      : Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? kHudAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: kHudAccent, size: 22),
          ],
        ),
      ),
    );
  }
}
