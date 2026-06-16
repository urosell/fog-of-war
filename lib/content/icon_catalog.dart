// Catálogo CERRADO de iconos para las colecciones.
//
// En la hoja de cálculo el icono de una colección se escribe por NOMBRE (texto),
// y aquí lo resolvemos a un IconData real. Es cerrado a propósito: Flutter
// optimiza ("tree-shaking") los iconos en compilación, así que no se puede
// construir un icono arbitrario en tiempo de ejecución; hay que elegir de esta
// lista. Para ofrecer un icono nuevo, añádelo aquí (y dime, que actualizo la
// lista que tienes en la hoja).

import 'package:flutter/material.dart';

/// Iconos disponibles para colecciones, por nombre estable. Las claves son las
/// que el usuario escribe en la columna `icon` de la hoja.
const Map<String, IconData> kCollectionIcons = {
  'architecture': Icons.architecture,
  'star': Icons.star,
  'auto_awesome': Icons.auto_awesome,
  'museum': Icons.museum,
  'tapas': Icons.tapas,
  'restaurant': Icons.restaurant,
  'place': Icons.place,
  'church': Icons.church,
  'park': Icons.park,
  'castle': Icons.castle,
  'landscape': Icons.landscape,
  'storefront': Icons.storefront,
  'local_cafe': Icons.local_cafe,
  'local_bar': Icons.local_bar,
  'shopping_bag': Icons.shopping_bag,
  'photo_camera': Icons.photo_camera,
  'directions_walk': Icons.directions_walk,
  'map': Icons.map,
  'flag': Icons.flag,
  'favorite': Icons.favorite,
  'sports_soccer': Icons.sports_soccer,
  'theater_comedy': Icons.theater_comedy,
  'palette': Icons.palette,
  'music_note': Icons.music_note,
  'menu_book': Icons.menu_book,
};

/// Icono por defecto si el nombre no está en el catálogo (o viene vacío).
const IconData kDefaultCollectionIcon = Icons.collections_bookmark;

/// Resuelve un nombre de icono a su IconData (cae al por defecto si no existe).
IconData iconFromName(String? name) {
  if (name == null) return kDefaultCollectionIcon;
  return kCollectionIcons[name.trim()] ?? kDefaultCollectionIcon;
}
