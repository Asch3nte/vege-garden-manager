import 'package:flutter/material.dart';

import '../../app/theme/couleurs_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../domain/value_objects/periode.dart';
import '../../l10n/app_localizations.dart';

/// A one-plant sowing/planting/harvest calendar: a 12-month header and a band
/// per known window, with the current month highlighted and a legend.
///
/// Each window is optional; when all are null the widget shows a "no data" note.
/// Shared by the catalogue plant sheet (and mirrors the Saison calendar view).
class CalendrierSemisRecolte extends StatelessWidget {
  final Periode? semis;
  final Periode? plantation;
  final Periode? recolte;
  final int moisActuel;

  const CalendrierSemisRecolte({
    required this.semis,
    required this.plantation,
    required this.recolte,
    required this.moisActuel,
    super.key,
  });

  static const List<String> _initiales = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
  ];
  static const double _largeurLabel = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final bandes = <(String, Periode, Color)>[
      if (semis != null) (l10n.saisonSemis, semis!, CouleursApp.decoVertMoyen),
      if (plantation != null)
        (l10n.saisonPlantation, plantation!, CouleursApp.accentPrimaireClair),
      if (recolte != null)
        (l10n.saisonRecolte, recolte!, CouleursApp.decoAubergine),
    ];

    if (bandes.isEmpty) {
      return Text(
        l10n.saisonNonRenseigne,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month-initials header.
        Row(
          children: [
            const SizedBox(width: _largeurLabel),
            for (var m = 1; m <= 12; m++)
              Expanded(
                child: Text(
                  _initiales[m - 1],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: m == moisActuel
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: m == moisActuel ? FontWeight.w700 : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s2),
        for (final (label, periode, couleur) in bandes)
          _Piste(
            label: label,
            periode: periode,
            couleur: couleur,
            moisActuel: moisActuel,
          ),
      ],
    );
  }
}

/// One 12-month track: cells filled where [periode] covers the month.
class _Piste extends StatelessWidget {
  final String label;
  final Periode periode;
  final Color couleur;
  final int moisActuel;

  const _Piste({
    required this.label,
    required this.periode,
    required this.couleur,
    required this.moisActuel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: CalendrierSemisRecolte._largeurLabel,
            child: Text(
              label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          for (var m = 1; m <= 12; m++)
            Expanded(
              child: Container(
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: periode.contientMois(m)
                      ? couleur
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                  border: m == moisActuel
                      ? Border.all(color: theme.colorScheme.primary, width: 1)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
