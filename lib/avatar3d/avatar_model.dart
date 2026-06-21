// Construcción por código del muñeco 3D del jugador (sin assets externos).
//
// Estilo BLOCKY (tipo Minecraft/Blockbench): el cuerpo se arma con cajas
// (cuboides) con zonas de color que insinúan ropa: cabeza (piel) con pelo,
// torso y brazos en "sudadera" azul con manos de piel, piernas en "pantalón"
// oscuro con zapatillas. Es un placeholder mientras se importa el modelo real
// hecho en Blockbench (ver assets/avatar/), y a la vez sirve de referencia de
// proporciones.
//
// Cada caja es un `Object` hijo de un `Object` raíz: tiene transform propio y
// las partes nombradas ('head','torso','armL','armR','legL','legR') sirven de
// "sockets" para colgar prendas más adelante.
//
// Notas de flutter_cube: no hay z-buffer (dibuja por profundidad), así que las
// cajas se TOCAN, no se interpenetran (si no, se ve translúcido). El sombreado
// es plano por cara con vértices duplicados; `_fixOutward()` orienta las caras
// hacia fuera para que el backface culling no deje agujeros.

import 'package:flutter/material.dart' show Color;
import 'package:flutter_cube/flutter_cube.dart' as cube;

// Acumulador de triángulos de una pieza.
class _Part {
  final List<cube.Vector3> _verts = [];
  final List<cube.Polygon> _polys = [];

  void _tri(cube.Vector3 a, cube.Vector3 b, cube.Vector3 c) {
    final i = _verts.length;
    _verts..add(a)..add(b)..add(c);
    _polys.add(cube.Polygon(i, i + 1, i + 2));
  }

  void _quad(cube.Vector3 a, cube.Vector3 b, cube.Vector3 c, cube.Vector3 d) {
    _tri(a, b, c);
    _tri(a, c, d);
  }

  // Reordena cada cara para que su normal apunte HACIA FUERA del centro de la
  // pieza (válido porque las cajas son convexas y centradas en su origen). Evita
  // tener que acertar el winding a mano (una cara al revés = agujero/translúcido).
  void _fixOutward() {
    for (final poly in _polys) {
      final a = _verts[poly.vertex0];
      final b = _verts[poly.vertex1];
      final c = _verts[poly.vertex2];
      final normal = (b - a).cross(c - a);
      final centroid = (a + b + c)..scale(1 / 3);
      if (normal.dot(centroid) < 0) {
        final t = poly.vertex1;
        poly.vertex1 = poly.vertex2;
        poly.vertex2 = t;
      }
    }
  }

  cube.Mesh toMesh(Color color) {
    _fixOutward();
    final material = cube.Material()
      ..diffuse = cube.fromColor(color)
      ..ambient = cube.fromColor(color)
      ..specular = cube.Vector3.zero();
    return cube.Mesh(vertices: _verts, indices: _polys, material: material);
  }
}

// Caja (cuboide) de tamaño width×height×depth, centrada en el origen.
_Part _box(double width, double height, double depth) {
  final p = _Part();
  final x = width / 2, y = height / 2, z = depth / 2;
  final v000 = cube.Vector3(-x, -y, -z);
  final v100 = cube.Vector3(x, -y, -z);
  final v110 = cube.Vector3(x, y, -z);
  final v010 = cube.Vector3(-x, y, -z);
  final v001 = cube.Vector3(-x, -y, z);
  final v101 = cube.Vector3(x, -y, z);
  final v111 = cube.Vector3(x, y, z);
  final v011 = cube.Vector3(-x, y, z);
  p._quad(v000, v100, v110, v010); // -Z
  p._quad(v001, v101, v111, v011); // +Z
  p._quad(v000, v001, v011, v010); // -X
  p._quad(v100, v101, v111, v110); // +X
  p._quad(v010, v110, v111, v011); // +Y
  p._quad(v000, v100, v101, v001); // -Y
  return p;
}

// Paleta del muñeco (zonas de color que insinúan la ropa).
const Color _kSkin = Color(0xFFE8B48C);
const Color _kHair = Color(0xFF6B4A2F);
const Color _kHoodie = Color(0xFF5BA3DA);
const Color _kPants = Color(0xFF383D45);
const Color _kShoes = Color(0xFFF2F2F2);
const Color _kEye = Color(0xFF33373F); // ojos (casi negro)
const Color _kMouth = Color(0xFF8A4E48); // boca (marrón apagado)
const Color _kCheek = Color(0xFFE89A92); // mejillas (rosa suave)

// Color base (compat. con código que aún lo importe; ya no se usa de fondo).
const Color kDefaultBodyColor = _kHoodie;

/// Construye el muñeco blocky como un `Object` raíz con las partes del cuerpo
/// como hijos nombrados ('head','torso','armL','armR','legL','legR'), listos
/// para colgarles prendas. Proporciones tipo Minecraft, ~2.26 de alto, centrado
/// verticalmente cerca del origen.
cube.Object buildMannequin({Color? color}) {
  final root = cube.Object(name: 'avatar');

  // Añade una caja [part] con [color] en [position], opcionalmente con [name].
  void add(_Part part, Color color, cube.Vector3 position, [String? name]) {
    root.add(cube.Object(
      name: name,
      mesh: part.toMesh(color),
      position: position,
      lighting: true,
      backfaceCulling: true,
    ));
  }

  // --- Piernas (x=±0.14, se tocan en el centro) ---
  for (final side in const [-1.0, 1.0]) {
    final x = side * 0.14;
    add(_box(0.28, 0.72, 0.28), _kPants, cube.Vector3(x, -0.64, 0),
        side < 0 ? 'legL' : 'legR'); // pantalón
    add(_box(0.28, 0.12, 0.36), _kShoes, cube.Vector3(x, -1.06, 0.04)); // zapatilla
  }

  // --- Torso (sudadera) ---
  add(_box(0.56, 0.84, 0.30), _kHoodie, cube.Vector3(0, 0.14, 0), 'torso');

  // --- Brazos (x=±0.42, pegados al torso): manga + mano ---
  for (final side in const [-1.0, 1.0]) {
    final x = side * 0.42;
    add(_box(0.28, 0.70, 0.28), _kHoodie, cube.Vector3(x, 0.21, 0),
        side < 0 ? 'armL' : 'armR'); // manga
    add(_box(0.28, 0.14, 0.28), _kSkin, cube.Vector3(x, -0.21, 0)); // mano
  }

  // --- Cabeza (piel) con pelo encima ---
  add(_box(0.56, 0.36, 0.56), _kSkin, cube.Vector3(0, 0.74, 0), 'head'); // cara
  add(_box(0.56, 0.22, 0.56), _kHair, cube.Vector3(0, 1.03, 0)); // pelo

  // --- Rasgos de la cara, en la cara frontal de la cabeza (lado -Z, hacia la
  // cámara), sobresaliendo un pelín para que se lean como pegatinas. ---
  const double faceZ = -0.295; // un poco por delante de la cara (-0.28)
  for (final side in const [-1.0, 1.0]) {
    add(_box(0.08, 0.10, 0.04), _kEye, cube.Vector3(side * 0.11, 0.80, faceZ)); // ojo
    add(_box(0.07, 0.05, 0.03), _kCheek, cube.Vector3(side * 0.17, 0.70, faceZ)); // mejilla
  }
  add(_box(0.14, 0.035, 0.04), _kMouth, cube.Vector3(0, 0.65, faceZ)); // boca

  return root;
}
