// Catálogo de personalización del marcador de posición del jugador (su "avatar"
// en el mapa). Define los iconos y colores disponibles y el widget que lo pinta,
// compartido entre el mapa y la pantalla de Ajustes para que se vean idénticos.

import 'package:flutter/material.dart';

/// Iconos elegibles para el marcador (índice = lo que se guarda en disco).
const List<IconData> kAvatarIcons = [
  Icons.navigation_rounded, // flecha de brújula (clásico GPS)
  Icons.directions_walk_rounded, // caminante
  Icons.pets, // huella de mascota
  Icons.rocket_launch_rounded, // cohete
  Icons.local_fire_department_rounded, // llama
];

/// Colores elegibles para el marcador (índice = lo que se guarda en disco).
const List<Color> kAvatarColors = [
  Color(0xFF2E7DF6), // azul
  Color(0xFF4DE3C2), // turquesa
  Color(0xFFFFD166), // oro
  Color(0xFFFF7A9C), // coral
  Color(0xFFB388FF), // morado
  Color(0xFF53D769), // verde
  Color(0xFFFF9F40), // naranja
  Color(0xFFFF5C5C), // rojo
];

/// Dibuja el marcador del jugador: círculo de color con borde blanco, sombra y
/// el icono elegido en el centro. [size] escala todo proporcionalmente.
class AvatarMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AvatarMarker({
    super.key,
    required this.icon,
    required this.color,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.09),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
          // Halo tenue del propio color, para que "brille" sobre el mapa.
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.56),
    );
  }
}
