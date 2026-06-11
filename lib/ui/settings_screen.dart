// Pantalla de Ajustes: por ahora, personalizar el marcador del jugador.
//
// Muestra un preview grande del marcador y dos secciones para elegir icono y
// color. Los cambios se aplican y guardan al instante (el AvatarController
// notifica, así que el preview y el mapa se actualizan en vivo).

import 'package:flutter/material.dart';

import '../avatar/avatar.dart';
import '../avatar/avatar_controller.dart';

/// Fondo oscuro, en sintonía con el tono de la niebla (igual que las demás
/// pantallas de la app).
const Color _kBackground = Color(0xFF161A21);

class SettingsScreen extends StatelessWidget {
  final AvatarController avatar;

  const SettingsScreen({super.key, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ajustes'),
      ),
      body: ListenableBuilder(
        listenable: avatar,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _PreviewCard(icon: avatar.icon, color: avatar.color),
              const SizedBox(height: 28),
              const _SectionTitle('Icono'),
              const SizedBox(height: 12),
              _IconPicker(
                selected: avatar.iconIndex,
                color: avatar.color,
                onPick: avatar.setIcon,
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Color'),
              const SizedBox(height: 12),
              _ColorPicker(
                selected: avatar.colorIndex,
                onPick: avatar.setColor,
              ),
            ],
          );
        },
      ),
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
            'Tu marcador en el mapa',
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
