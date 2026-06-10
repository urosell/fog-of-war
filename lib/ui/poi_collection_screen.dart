// Pantalla de colección de POIs (tipo "logros").
//
// Muestra todos los POIs conocidos agrupados por categoría: los descubiertos
// con su nombre y puntos, y los que aún no has visitado como bloqueados (nombre
// oculto, candado) para picar la curiosidad y animar a explorar.
//
// Al tocar un POI ya descubierto, la pantalla se cierra devolviéndolo, y el
// mapa se centra en él (lo hace quien la abrió, en main.dart).

import 'package:flutter/material.dart';

import '../poi/poi.dart';
import '../poi/poi_controller.dart';
import 'hud.dart';

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
  }
}

/// Color ámbar de un POI descubierto (mismo "tesoro" que sus marcadores).
const Color _kDiscoveredColor = Color(0xFFFFB300);

/// Fondo oscuro de la pantalla, en sintonía con el tono de la niebla.
const Color _kBackground = Color(0xFF161A21);

class PoiCollectionScreen extends StatelessWidget {
  final PoiController poiController;

  const PoiCollectionScreen({super.key, required this.poiController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Colección de POIs'),
      ),
      // Se redibuja sola si descubres un POI mientras la tienes abierta.
      body: ListenableBuilder(
        listenable: poiController,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(poiController: poiController),
              const SizedBox(height: 20),
              ..._buildCategories(context),
            ],
          );
        },
      ),
    );
  }

  // Construye, por cada categoría con POIs, su cabecera y sus tarjetas
  // (descubiertos primero). Las categorías van en el orden del enum.
  List<Widget> _buildCategories(BuildContext context) {
    final widgets = <Widget>[];
    for (final categoria in PoiCategory.values) {
      final delGrupo =
          poiController.allPois.where((p) => p.category == categoria).toList();
      if (delGrupo.isEmpty) continue;

      // Descubiertos primero, dentro del grupo, para que se vean los logros.
      delGrupo.sort((a, b) {
        final da = poiController.isDiscovered(a) ? 0 : 1;
        final db = poiController.isDiscovered(b) ? 0 : 1;
        return da.compareTo(db);
      });

      final descubiertos =
          delGrupo.where(poiController.isDiscovered).length;

      widgets.add(_CategoryHeader(
        categoria: categoria,
        descubiertos: descubiertos,
        total: delGrupo.length,
      ));
      for (final poi in delGrupo) {
        widgets.add(_PoiCard(
          poi: poi,
          discovered: poiController.isDiscovered(poi),
        ));
      }
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }
}

// Cabecera con el progreso global: contador, barra y puntos totales.
class _Header extends StatelessWidget {
  final PoiController poiController;

  const _Header({required this.poiController});

  @override
  Widget build(BuildContext context) {
    final descubiertos = poiController.discoveredCount;
    final total = poiController.totalCount;
    final fraccion = total == 0 ? 0.0 : descubiertos / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: kHudAccent, size: 28),
              const SizedBox(width: 10),
              Text(
                '$descubiertos / $total descubiertos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _PointsBadge(points: poiController.totalPoints),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraccion,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation(kHudAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// Insignia con los puntos totales acumulados.
class _PointsBadge extends StatelessWidget {
  final int points;

  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kHudAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$points pts',
        style: const TextStyle(
          color: kHudAccent,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Cabecera de un grupo de categoría: "Monumentos  2/4".
class _CategoryHeader extends StatelessWidget {
  final PoiCategory categoria;
  final int descubiertos;
  final int total;

  const _CategoryHeader({
    required this.categoria,
    required this.descubiertos,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(iconForCategory(categoria),
              color: Colors.white.withValues(alpha: 0.55), size: 18),
          const SizedBox(width: 8),
          Text(
            categoria.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$descubiertos/$total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ],
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
