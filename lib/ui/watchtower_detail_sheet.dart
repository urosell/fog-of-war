// Panel inferior (bottom sheet) con el detalle de una atalaya al tocarla en el
// mapa. Es informativo y compacto (las atalayas no puntúan ni tienen ficha
// "marketiniana" como los POIs): muestra el nombre del lugar, si está activada
// o no, y una frase que explica su mecánica de avistado.

import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../watchtower/watchtower.dart';

// Tokens compartidos con la ficha de POI (poi_detail_sheet.dart).
const Color _kBg = Color(0xFF171A21);
const Color _kTextPrimary = Color(0xFFFBF9F5);
const Color _kTextSecondary = Color(0xFFB4B2A9);
const double _kRadiusCard = 28;

// Turquesa de las atalayas (mismo par que el marcador en el mapa).
const Color _kActive = Color(0xFF1FB8C4);
const Color _kInactive = Color(0xFF566B8C);

/// Abre el panel de detalle de [tower]. [activated] decide el color, el icono,
/// la etiqueta de estado y qué frase se muestra.
Future<void> showWatchtowerDetailSheet({
  required BuildContext context,
  required Watchtower tower,
  required bool activated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _WatchtowerDetailSheet(tower: tower, activated: activated),
  );
}

class _WatchtowerDetailSheet extends StatelessWidget {
  final Watchtower tower;
  final bool activated;

  const _WatchtowerDetailSheet({required this.tower, required this.activated});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = activated ? _kActive : _kInactive;

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(_kRadiusCard)),
      child: Container(
        color: _kBg,
        child: Padding(
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
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: Icon(
                        activated
                            ? Icons.visibility
                            : Icons.visibility_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tower.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activated
                                    ? l.watchtowerSheetStatusActive
                                    : l.watchtowerSheetStatusInactive,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  activated
                      ? l.watchtowerSheetHintActive
                      : l.watchtowerSheetHint,
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
        ),
      ),
    );
  }
}
