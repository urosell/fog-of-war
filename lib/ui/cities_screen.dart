// Pantalla "Cities": listado de ciudades con su progreso de exploración.
//
// Lista todas las ciudades jugables (kCities) mostrando, para cada una, el
// porcentaje de celdas desveladas dentro de su caja y cuántos POIs se han
// descubierto allí. Al tocar una ciudad se devuelve a main.dart para centrar el
// mapa en ella. Mismo estilo translúcido (velo + blur) que el hub de colecciones.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../cities/city.dart';
import '../fog/fog_controller.dart';
import '../l10n/l10n_ext.dart';
import '../poi/poi_controller.dart';
import 'hud.dart' show kHudAccent, kHudGold, kHudCoral;

/// Velo oscuro semitransparente (igual que en colecciones) para dejar entrever
/// el mapa difuminado por detrás manteniendo el texto legible.
const Color _kScrim = Color(0xC2161A21);

class CitiesScreen extends StatelessWidget {
  final FogController fogController;
  final PoiController poiController;

  /// Ciudades a mostrar (por defecto, todas las jugables).
  final List<City> cities;

  /// Id de la ciudad "activa" (la que se ve en el HUD), para destacarla.
  final String? activeCityId;

  const CitiesScreen({
    super.key,
    required this.fogController,
    required this.poiController,
    this.cities = kCities,
    this.activeCityId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _kScrim,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.citiesTitle),
      ),
      body: Stack(
        children: [
          // Mapa de fondo difuminado + velo oscuro.
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: _kScrim),
            ),
          ),
          // Se redibuja al desvelar celdas o descubrir POIs.
          ListenableBuilder(
            listenable: Listenable.merge([fogController, poiController]),
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final city in cities)
                    _CityCard(
                      city: city,
                      fogController: fogController,
                      poiController: poiController,
                      active: city.id == activeCityId,
                      onTap: () => Navigator.of(context).pop(city),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Tarjeta de una ciudad: nombre, % explorado y, debajo, celdas y POIs de la
// ciudad, más una barra fina con el porcentaje.
class _CityCard extends StatelessWidget {
  final City city;
  final FogController fogController;
  final PoiController poiController;
  final bool active;
  final VoidCallback onTap;

  const _CityCard({
    required this.city,
    required this.fogController,
    required this.poiController,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Contador incremental del FogController: evita recorrer todas las celdas
    // descubiertas por cada ciudad en cada redibujado.
    final cells = fogController.discoveredCountInCity(city.id);
    final percentage = city.percentageFromCount(cells);

    // POIs que caen dentro de la ciudad y cuántos están descubiertos.
    var poisTotal = 0;
    var poisDiscovered = 0;
    for (final poi in poiController.allPois) {
      if (!city.containsLatLng(poi.location)) continue;
      poisTotal++;
      if (poiController.isDiscovered(poi)) poisDiscovered++;
    }

    // Color de acento: dorado si es la ciudad activa, turquesa si ya la has
    // empezado a explorar, coral apagado si aún no has pisado nada.
    final Color accent = active
        ? kHudGold
        : (cells > 0 ? kHudAccent : kHudCoral);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_city_rounded,
                        color: accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  city.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              // Chip de "estás aquí" en la ciudad activa.
                              if (active) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.my_location,
                                    color: accent, size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.citiesStats(cells, poisDiscovered, poisTotal),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Porcentaje explorado (con 2 decimales: una ciudad es mucho
                    // terreno y el número suele ser pequeño pero honesto).
                    Text(
                      '${percentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    // Mínimo visible para que la barra no parezca "rota" al 0%.
                    value: (percentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
