// Pantalla "hub" de colecciones temáticas.
//
// Lista todas las colecciones (Ruta Gaudí, Otaku BCN...) con su progreso. Al
// tocar una, abre su detalle (PoiCollectionScreen). Si dentro del detalle el
// usuario toca un POI descubierto, ese POI "sube" hasta aquí y se devuelve a
// main.dart para centrar el mapa en él.

import 'package:flutter/material.dart';

import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import '../poi/poi_controller.dart';
import 'poi_collection_screen.dart';

/// Fondo oscuro, en sintonía con el tono de la niebla.
const Color _kBackground = Color(0xFF161A21);

class PoiCollectionsScreen extends StatelessWidget {
  final PoiController poiController;

  /// Colecciones a mostrar (por defecto las de Barcelona).
  final List<PoiCollection> collections;

  const PoiCollectionsScreen({
    super.key,
    required this.poiController,
    this.collections = kPoiCollections,
  });

  // Abre el detalle de una colección. Si vuelve un POI (el usuario lo tocó),
  // cerramos también este hub devolviéndolo para que main centre el mapa.
  Future<void> _abrir(BuildContext context, PoiCollection collection) async {
    final elegido = await Navigator.of(context).push<Poi>(
      MaterialPageRoute(
        builder: (_) => PoiCollectionScreen(
          poiController: poiController,
          collection: collection,
        ),
      ),
    );
    if (elegido != null && context.mounted) {
      Navigator.of(context).pop(elegido);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Colecciones'),
      ),
      // Se redibuja sola si descubres un POI mientras la tienes abierta.
      body: ListenableBuilder(
        listenable: poiController,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final c in collections)
                _CollectionCard(
                  collection: c,
                  poiController: poiController,
                  onTap: () => _abrir(context, c),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Tarjeta de una colección: icono+color del tema, nombre, descripción, contador
// y barra de progreso.
class _CollectionCard extends StatelessWidget {
  final PoiCollection collection;
  final PoiController poiController;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.collection,
    required this.poiController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = collection.poiIds.length;
    final descubiertos =
        collection.discoveredCount(poiController.isDiscoveredId);
    final fraccion = total == 0 ? 0.0 : descubiertos / total;
    final completa = total > 0 && descubiertos == total;
    final accent = collection.accent;

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
                      child: Icon(collection.icon, color: accent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            collection.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (completa)
                      Icon(Icons.verified, color: accent, size: 24)
                    else
                      Text(
                        '$descubiertos/$total',
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
                    value: fraccion,
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
