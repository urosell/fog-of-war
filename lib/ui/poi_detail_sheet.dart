// Panel inferior (bottom sheet) con el detalle de un POI al tocarlo en el mapa.
//
// Dos modos según el estado del POI:
//  - DESCUBIERTO: ficha "marketiniana" que invita a visitar el lugar: foto de
//    cabecera (o degradado si no hay), gancho de proximidad ("A 320 m de ti"),
//    stats (valoración, visita, cuánta gente lo exploró), descripción evocadora,
//    colecciones como cards con progreso (la destacada en dorado) y CTA para
//    llegar. Todos los datos extra son opcionales: la ficha degrada con
//    elegancia cuando faltan (sin foto → degradado; sin stats → se ocultan).
//  - AVISTADO (gris, revelado por una atalaya pero aún no visitado): teaser sin
//    destripar (categoría + "Pendiente de descubrir" + empujón motivador), sin
//    nombre ni enlace, para conservar el misterio.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_ext.dart';
import '../poi/poi.dart';
import '../poi/poi_collection.dart';
import 'poi_collection_screen.dart' show iconForCategory;

// Tokens del rediseño (mockup "foco-map-poi-card-redesign").
const Color _kBg = Color(0xFF171A21);
const Color _kAccent = Color(0xFFF5A623); // dorado de marca
const Color _kAccentText = Color(0xFF14161C); // texto sobre dorado
const Color _kTextPrimary = Color(0xFFFBF9F5);
const Color _kTextSecondary = Color(0xFFB4B2A9);
const Color _kTextMuted = Color(0xFF7A7973);
const Color _kSurfaceSubtle = Color(0x0AFFFFFF); // blanco al 4%
const Color _kBorderSubtle = Color(0x1AFFFFFF); // blanco al 10%
const Color _kOnlineDot = Color(0xFF3BD07A); // punto verde de proximidad
const Color _kGhost = Color(0xFF8A93A6); // gris azulado del marcador avistado
const double _kRadiusCard = 28;
const double _kRadiusInner = 18;
const double _kHeaderHeight = 210;

/// Abre el panel de detalle de [poi]. [collections] son SOLO las colecciones a
/// las que pertenece este POI (las calcula quien llama). [discovered] decide el
/// modo (ficha completa vs. teaser). [userPosition] permite el gancho de
/// proximidad; [cityName] la línea "BARRIO · CIUDAD"; [isDiscoveredId] el
/// progreso real de cada colección. [onCollectionTap], si se pasa, hace que las
/// cards de colección sean tocables: se cierra el panel y quien llama abre la
/// pantalla de esa colección.
Future<void> showPoiDetailSheet({
  required BuildContext context,
  required Poi poi,
  required List<PoiCollection> collections,
  required bool discovered,
  LatLng? userPosition,
  String? cityName,
  bool Function(String poiId)? isDiscoveredId,
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
      userPosition: userPosition,
      cityName: cityName,
      isDiscoveredId: isDiscoveredId,
      onCollectionTap: onCollectionTap,
    ),
  );
}

class _PoiDetailSheet extends StatelessWidget {
  final Poi poi;
  final List<PoiCollection> collections;
  final bool discovered;
  final LatLng? userPosition;
  final String? cityName;
  final bool Function(String poiId)? isDiscoveredId;
  final void Function(PoiCollection collection)? onCollectionTap;

  const _PoiDetailSheet({
    required this.poi,
    required this.collections,
    required this.discovered,
    this.userPosition,
    this.cityName,
    this.isDiscoveredId,
    this.onCollectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_kRadiusCard)),
      child: Container(
        color: _kBg,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: discovered ? _discovered(context) : _undiscovered(context),
      ),
    );
  }

  // --- POI descubierto: ficha completa -----------------------------------
  Widget _discovered(BuildContext context) {
    final l = context.l10n;
    final code = Localizations.localeOf(context).languageCode;
    final description = poi.localizedDescription(code);
    final stats = _stats(context, code);

    // La destacada (dorada) primero, conservando el orden dentro de cada grupo.
    final sorted = [
      ...collections.where((c) => c.featured),
      ...collections.where((c) => !c.featured),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context, code),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stats.isNotEmpty) ...[
                    Row(
                      children: [
                        for (var i = 0; i < stats.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: stats[i]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (description != null) ...[
                    Text(
                      description,
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 14.5,
                        height: 1.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    l.poiSheetAppearsIn.toUpperCase(),
                    style: const TextStyle(
                      color: _kTextMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (collections.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '—',
                        style: TextStyle(color: _kTextMuted, fontSize: 14),
                      ),
                    )
                  else
                    for (final c in sorted) ...[
                      _collectionCard(context, c, code),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openMaps(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: _kAccentText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: Text(
                        l.poiSheetDirections,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Cabecera: foto (o degradado) + badges + ubicación + título ---------
  Widget _header(BuildContext context, String code) {
    final l = context.l10n;
    final locationLine =
        [?poi.neighborhood, ?cityName].join(' · ').toUpperCase();

    final distance = userPosition == null
        ? null
        : const Distance().as(LengthUnit.Meter, userPosition!, poi.location);

    return SizedBox(
      height: _kHeaderHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (poi.imageUrl != null)
            Image.network(
              poi.imageUrl!,
              fit: BoxFit.cover,
              // Mientras carga (y si falla) se ve el degradado: la cabecera
              // nunca queda vacía ni "rota".
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _fallbackBackground(),
              errorBuilder: (_, _, _) => _fallbackBackground(),
            )
          else
            _fallbackBackground(),
          // Degradado oscuro hacia el pie para que el texto siempre se lea.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 0.88, 1.0],
                colors: [Colors.transparent, Color(0xD9171A21), _kBg],
              ),
            ),
          ),
          // Asa para arrastrar/cerrar.
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (distance != null)
            Positioned(
              top: 20,
              left: 16,
              child: _proximityBadge(
                l.poiSheetDistanceAway(_formatDistance(distance, code)),
              ),
            ),
          Positioned(
            top: 20,
            right: 16,
            child: _pointsBadge('+${context.l10n.pointsBadge(poi.points)}'),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (locationLine.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.place, size: 12, color: _kAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  poi.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fondo de cabecera cuando no hay foto: degradado radial cálido (combina
  /// con el dorado de marca) + icono grande de la categoría, muy tenue.
  Widget _fallbackBackground() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.4, -0.7),
          radius: 1.4,
          stops: [0.0, 0.45, 1.0],
          colors: [Color(0xFF6B4E2E), Color(0xFF3A2C1A), Color(0xFF1E1710)],
        ),
      ),
      child: Center(
        child: Icon(
          iconForCategory(poi.category),
          size: 84,
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
    );
  }

  Widget _proximityBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xB314161C), // translúcido oscuro sobre la foto
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _kOnlineDot,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _kOnlineDot.withValues(alpha: 0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _kAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 15, color: _kAccentText),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: _kAccentText,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // --- Fila de stats (solo las que tengan dato; si no hay ninguna, nada) --
  List<Widget> _stats(BuildContext context, String code) {
    final l = context.l10n;
    final out = <Widget>[];
    if (poi.rating != null) {
      final nf = NumberFormat.decimalPatternDigits(locale: code, decimalDigits: 1);
      out.add(_statTile(Icons.star_rounded, _kAccent, nf.format(poi.rating),
          l.poiSheetStatRating));
    }
    if (poi.visitMinutes != null) {
      out.add(_statTile(Icons.schedule, _kTextSecondary,
          _formatVisit(poi.visitMinutes!), l.poiSheetStatVisit));
    }
    if (poi.exploredCount != null) {
      out.add(_statTile(Icons.groups_rounded, _kTextSecondary,
          _formatCount(poi.exploredCount!, code), l.poiSheetStatExplored));
    }
    return out;
  }

  Widget _statTile(IconData icon, Color iconColor, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _kSurfaceSubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _kTextMuted,
              fontSize: 11.5,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // --- Cards de colecciones ("Aparece en") --------------------------------
  Widget _collectionCard(BuildContext context, PoiCollection c, String code) {
    final l = context.l10n;
    final tappable = onCollectionTap != null;
    final featured = c.featured;

    // Destacada: progreso real "N de M completados". Neutra: contexto
    // "N paradas · tagline". Sin función de progreso, la destacada cae al
    // formato neutro.
    final String subtitle;
    if (featured && isDiscoveredId != null) {
      subtitle = l.poiSheetProgress(
          c.discoveredCount(isDiscoveredId!), c.poiIds.length);
    } else {
      final tagline = c.localizedDescription(code);
      subtitle = tagline.isEmpty
          ? l.poiSheetStops(c.poiIds.length)
          : '${l.poiSheetStops(c.poiIds.length)} · $tagline';
    }

    final titleColor = featured ? _kAccentText : _kTextPrimary;
    final subtitleColor =
        featured ? _kAccentText.withValues(alpha: 0.72) : _kTextMuted;

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: featured ? _kAccent : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(_kRadiusInner),
        border: featured ? null : Border.all(color: _kBorderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: featured
                  ? _kAccentText.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              c.icon,
              size: 19,
              color: featured ? _kAccentText : const Color(0xFFE8E6E1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.localizedName(code),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (tappable)
            Icon(Icons.chevron_right,
                size: 20, color: featured ? _kAccentText : _kTextMuted),
        ],
      ),
    );
    if (!tappable) return card;
    // Cierra el panel y delega la navegación a quien abrió el sheet.
    return InkWell(
      borderRadius: BorderRadius.circular(_kRadiusInner),
      onTap: () {
        Navigator.of(context).pop();
        onCollectionTap!(c);
      },
      child: card,
    );
  }

  // --- POI avistado (no descubierto): teaser sin destripar ----------------
  Widget _undiscovered(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kGhost,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Icon(iconForCategory(poi.category),
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l.poiSheetUndiscoveredTitle,
                    style: const TextStyle(
                      color: _kTextPrimary,
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
                color: _kTextSecondary,
                fontSize: 15,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- Formateadores -------------------------------------------------------

  /// "320 m" (redondeado a decenas) o "1,2 km" (separador según idioma).
  String _formatDistance(double meters, String code) {
    if (meters < 1000) {
      final m = meters < 100 ? meters.round() : (meters / 10).round() * 10;
      return '$m m';
    }
    final nf = NumberFormat.decimalPatternDigits(
        locale: code, decimalDigits: meters < 10000 ? 1 : 0);
    return '${nf.format(meters / 1000)} km';
  }

  /// "45 min", "~2 h" o "~1 h 30".
  String _formatVisit(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '~$h h' : '~$h h $rest';
  }

  /// "845" o "1,2k" (separador según idioma).
  String _formatCount(int n, String code) {
    if (n < 1000) return '$n';
    final v = n / 1000;
    final nf = NumberFormat.decimalPatternDigits(
        locale: code, decimalDigits: v >= 10 ? 0 : 1);
    return '${nf.format(v)}k';
  }

  Future<void> _openMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    // launchUrl puede lanzar (URL malformada, sin app que la abra...): un
    // enlace roto en el contenido no debe tumbar la app, solo avisar.
    var ok = false;
    try {
      final uri = Uri.parse(poi.mapsUrl);
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.poiSheetMapsError)),
      );
      return;
    }
    navigator.pop();
  }
}
