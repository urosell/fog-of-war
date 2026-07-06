// Panel inferior (bottom sheet) con el detalle de un POI al tocarlo en el mapa.
//
// Dos modos según el estado del POI:
//  - DESCUBIERTO: nombre, las colecciones a las que pertenece y un botón para
//    abrirlo en Google Maps (enlace de la hoja o generado desde lat/lon).
//  - AVISTADO (gris, revelado por una atalaya pero aún no visitado): teaser sin
//    destripar (categoría + "Pendiente de descubrir" + empujón motivador), sin
//    nombre ni enlace, para conservar el misterio.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_ext.dart';
import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import 'poi_collection_screen.dart' show iconForCategory;

const Color _kBackground = Color(0xFF1B2029);
const Color _kDiscovered = Color(0xFFFFB300); // ámbar "tesoro"
const Color _kGhost = Color(0xFF8A93A6); // gris azulado del marcador avistado

/// Abre el panel de detalle de [poi]. [collections] son SOLO las colecciones a
/// las que pertenece este POI (las calcula quien llama). [discovered] decide el
/// modo (detalle completo vs. teaser). [onCollectionTap], si se pasa, hace que
/// los chips de colección sean tocables: se cierra el panel y quien llama abre
/// la pantalla de esa colección.
Future<void> showPoiDetailSheet({
  required BuildContext context,
  required Poi poi,
  required List<PoiCollection> collections,
  required bool discovered,
  void Function(PoiCollection collection)? onCollectionTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PoiDetailSheet(
      poi: poi,
      collections: collections,
      discovered: discovered,
      onCollectionTap: onCollectionTap,
    ),
  );
}

class _PoiDetailSheet extends StatelessWidget {
  final Poi poi;
  final List<PoiCollection> collections;
  final bool discovered;
  final void Function(PoiCollection collection)? onCollectionTap;

  const _PoiDetailSheet({
    required this.poi,
    required this.collections,
    required this.discovered,
    this.onCollectionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 16)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asa para arrastrar/cerrar.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (discovered) ..._discovered(context) else ..._undiscovered(context),
          ],
        ),
      ),
    );
  }

  // --- POI descubierto: detalle completo --------------------------------
  List<Widget> _discovered(BuildContext context) {
    final l = context.l10n;
    final code = Localizations.localeOf(context).languageCode;
    return [
      Row(
        children: [
          _categoryBadge(_kDiscovered),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              poi.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _pointsBadge(l.pointsBadge(poi.points)),
        ],
      ),
      const SizedBox(height: 22),
      Text(
        l.poiSheetInCollections,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          decoration: TextDecoration.none,
        ),
      ),
      const SizedBox(height: 10),
      if (collections.isEmpty)
        Text(
          l.poiSheetNoCollections,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            decoration: TextDecoration.none,
          ),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in collections) _collectionChip(context, c, code),
          ],
        ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _openMaps(context),
          style: FilledButton.styleFrom(
            backgroundColor: _kDiscovered,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.map_outlined),
          label: Text(
            l.poiSheetOpenInMaps,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ];
  }

  // --- POI avistado (no descubierto): teaser sin destripar --------------
  List<Widget> _undiscovered(BuildContext context) {
    final l = context.l10n;
    return [
      Row(
        children: [
          _categoryBadge(_kGhost),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l.poiSheetUndiscoveredTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Text(
        l.poiSheetUndiscoveredHint,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          height: 1.4,
          decoration: TextDecoration.none,
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _categoryBadge(Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Icon(iconForCategory(poi.category), color: Colors.white, size: 24),
    );
  }

  Widget _pointsBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kDiscovered.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _kDiscovered,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _collectionChip(BuildContext context, PoiCollection c, String code) {
    final tappable = onCollectionTap != null;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(c.icon, color: c.accent, size: 16),
          const SizedBox(width: 6),
          Text(
            c.localizedName(code),
            style: TextStyle(
              color: c.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          // Chevron sutil que indica que el chip lleva a la colección.
          if (tappable) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: c.accent, size: 16),
          ],
        ],
      ),
    );
    if (!tappable) return chip;
    // Cierra el panel y delega la navegación a quien abrió el sheet.
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).pop();
        onCollectionTap!(c);
      },
      child: chip,
    );
  }

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    final uri = Uri.parse(poi.mapsUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.poiSheetMapsError)),
      );
      return;
    }
    navigator.pop();
  }
}
