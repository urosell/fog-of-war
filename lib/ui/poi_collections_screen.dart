// Pantalla "hub" de colecciones temáticas.
//
// Lista todas las colecciones (Ruta Gaudí, Otaku BCN...) con su progreso. Al
// tocar una, abre su detalle (PoiCollectionScreen). Si dentro del detalle el
// usuario toca un POI descubierto, ese POI "sube" hasta aquí y se devuelve a
// main.dart para centrar el mapa en él.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../mission/mission_controller.dart';
import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import '../poi/poi_controller.dart';
import 'poi_collection_screen.dart';
import 'transitions.dart';

/// Velo oscuro semitransparente: deja entrever el mapa por detrás (la ruta se
/// abre sin opacidad) manteniendo el texto legible. A juego con el estilo glass.
const Color _kScrim = Color(0xC2161A21); // ~76% de opacidad

class PoiCollectionsScreen extends StatelessWidget {
  final PoiController poiController;
  final MissionController mission;

  /// Colecciones a mostrar (por defecto las de Barcelona).
  final List<PoiCollection> collections;

  const PoiCollectionsScreen({
    super.key,
    required this.poiController,
    required this.mission,
    this.collections = kPoiCollections,
  });

  // Abre el detalle de una colección. Si vuelve un POI (el usuario lo tocó),
  // cerramos también este hub devolviéndolo para que main centre el mapa.
  Future<void> _abrir(BuildContext context, PoiCollection collection) async {
    final elegido = await Navigator.of(context).push<Poi>(
      appRoute(PoiCollectionScreen(
        poiController: poiController,
        collection: collection,
        mission: mission,
      )),
    );
    if (elegido != null && context.mounted) {
      Navigator.of(context).pop(elegido);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparente para que se vea el mapa por detrás; el velo + blur va en
      // el body para difuminar y oscurecer suavemente ese mapa.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _kScrim,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(context.l10n.collectionsTitle),
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
          // Se redibuja al descubrir un POI o al cambiar la misión fijada.
          ListenableBuilder(
            listenable: Listenable.merge([poiController, mission]),
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final c in collections)
                    _CollectionCard(
                      collection: c,
                      poiController: poiController,
                      pinned: mission.isPinned(c.id),
                      onTap: () => _abrir(context, c),
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

// Tarjeta de una colección: icono+color del tema, nombre, descripción, contador
// y barra de progreso.
class _CollectionCard extends StatelessWidget {
  final PoiCollection collection;
  final PoiController poiController;
  final bool pinned;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.collection,
    required this.poiController,
    required this.pinned,
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
                            collection.localizedName(
                                Localizations.localeOf(context).languageCode),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            collection.localizedDescription(
                                Localizations.localeOf(context).languageCode),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Indicador de "misión activa" en esta colección.
                    if (pinned) ...[
                      Icon(Icons.push_pin, color: accent, size: 18),
                      const SizedBox(width: 8),
                    ],
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
