// Pantalla de DETALLE de una colección temática (p. ej. "Ruta Gaudí").
//
// Muestra los POIs de esa colección en orden: los descubiertos con su nombre y
// puntos, y los que aún no has visitado como bloqueados (nombre oculto, candado)
// para picar la curiosidad. La cabecera lleva el progreso de la colección.
//
// Al tocar un POI ya descubierto, la pantalla se cierra devolviéndolo, y el
// mapa se centra en él (lo hace quien la abrió, en main.dart).

import 'package:flutter/material.dart';

import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import '../poi/poi_controller.dart';
import 'leaderboard_screen.dart';
import 'transitions.dart';

/// Icono representativo de cada categoría de POI. Público para reutilizarlo
/// tanto aquí como en los marcadores del mapa.
IconData iconForCategory(PoiCategory c) {
  switch (c) {
    case PoiCategory.monumento:
      return Icons.account_balance;
    case PoiCategory.iglesia:
      return Icons.church;
    case PoiCategory.museo:
      return Icons.museum;
    case PoiCategory.parque:
      return Icons.park;
    case PoiCategory.mirador:
      return Icons.landscape;
    case PoiCategory.plaza:
      return Icons.location_city;
    case PoiCategory.tienda:
      return Icons.storefront;
  }
}

/// Color ámbar de un POI descubierto (mismo "tesoro" que sus marcadores).
const Color _kDiscoveredColor = Color(0xFFFFB300);

/// Fondo oscuro de la pantalla, en sintonía con el tono de la niebla.
const Color _kBackground = Color(0xFF161A21);

class PoiCollectionScreen extends StatelessWidget {
  final PoiController poiController;
  final PoiCollection collection;

  const PoiCollectionScreen({
    super.key,
    required this.poiController,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Clasificación de esta colección',
            onPressed: () => Navigator.of(context).push(
              appRoute(CollectionLeaderboardScreen(
                poiController: poiController,
                collection: collection,
              )),
            ),
          ),
        ],
      ),
      // Se redibuja sola si descubres un POI mientras la tienes abierta.
      body: ListenableBuilder(
        listenable: poiController,
        builder: (context, _) {
          final pois = collection.resolvePois(poiController.poiById);
          // Descubiertos primero (manteniendo el orden de la colección dentro
          // de cada grupo) para que se vean los logros arriba.
          final ordenados = [
            ...pois.where(poiController.isDiscovered),
            ...pois.where((p) => !poiController.isDiscovered(p)),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(poiController: poiController, collection: collection),
              const SizedBox(height: 20),
              for (final poi in ordenados)
                _PoiCard(
                  poi: poi,
                  discovered: poiController.isDiscovered(poi),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Cabecera con el progreso de la colección: icono, descripción, barra y puntos.
class _Header extends StatelessWidget {
  final PoiController poiController;
  final PoiCollection collection;

  const _Header({required this.poiController, required this.collection});

  @override
  Widget build(BuildContext context) {
    final pois = collection.resolvePois(poiController.poiById);
    final descubiertos = collection.discoveredCount(poiController.isDiscoveredId);
    final total = pois.length;
    final fraccion = total == 0 ? 0.0 : descubiertos / total;
    final puntos = pois
        .where(poiController.isDiscovered)
        .fold<int>(0, (s, p) => s + p.points);
    final completa = total > 0 && descubiertos == total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: collection.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: collection.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(collection.icon, color: collection.accent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$descubiertos / $total descubiertos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _PointsBadge(points: puntos, accent: collection.accent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completa ? '¡Colección completada! 🎉' : collection.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 14,
              fontWeight: completa ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraccion,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation(collection.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// Insignia con los puntos acumulados en esta colección.
class _PointsBadge extends StatelessWidget {
  final int points;
  final Color accent;

  const _PointsBadge({required this.points, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$points pts',
        style: TextStyle(
          color: accent,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Tarjeta de un POI. Descubierto: nombre + puntos + ✓, tocable (centra el mapa).
// Bloqueado: nombre oculto, icono gris con candado y los puntos que daría.
class _PoiCard extends StatelessWidget {
  final Poi poi;
  final bool discovered;

  const _PoiCard({required this.poi, required this.discovered});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: discovered
            ? _kDiscoveredColor.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: discovered
              ? _kDiscoveredColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          // Icono de la categoría: ámbar si está descubierto, gris si no.
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: discovered
                  ? _kDiscoveredColor
                  : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              discovered ? iconForCategory(poi.category) : Icons.lock,
              color: discovered
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.40),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discovered ? poi.name : '?????',
                  style: TextStyle(
                    color: discovered
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: discovered ? 0 : 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  discovered
                      ? '+${poi.points} puntos'
                      : 'Por descubrir · ${poi.points} pts',
                  style: TextStyle(
                    color: discovered
                        ? _kDiscoveredColor
                        : Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (discovered)
            const Icon(Icons.check_circle, color: _kDiscoveredColor, size: 22)
          else
            Icon(Icons.lock_outline,
                color: Colors.white.withValues(alpha: 0.25), size: 20),
        ],
      ),
    );

    // Solo los descubiertos son tocables: al pulsarlos, cerramos la pantalla
    // devolviendo el POI para que el mapa se centre en él.
    if (!discovered) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pop(poi),
      child: card,
    );
  }
}
