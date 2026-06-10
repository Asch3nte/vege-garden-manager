import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/meteo_detail_notifier.dart';
import '../../domain/value_objects/prevision_horaire.dart';
import '../../l10n/app_localizations.dart';

/// Opens the hourly weather detail (pushed full-screen).
Future<void> ouvrirMeteoDetail(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const EcranMeteoDetail()),
  );
}

/// Hourly weather detail: a day selector + the selected day's hourly forecast.
class EcranMeteoDetail extends ConsumerStatefulWidget {
  const EcranMeteoDetail({super.key});

  @override
  ConsumerState<EcranMeteoDetail> createState() => _EcranMeteoDetailState();
}

class _EcranMeteoDetailState extends ConsumerState<EcranMeteoDetail> {
  /// Day-of-month of the selected day (null → first available).
  int? _jourChoisi;

  static DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(meteoHoraireProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.meteoDetailTitre)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(EspacementsApp.s6),
            child: Text(l10n.meteoDetailErreur, textAlign: TextAlign.center),
          ),
        ),
        data: (heures) {
          if (heures.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(EspacementsApp.s6),
                child: Text(l10n.meteoSansPosition, textAlign: TextAlign.center),
              ),
            );
          }

          // Distinct days, in order.
          final jours = <DateTime>[];
          for (final h in heures) {
            final j = _jour(h.heure);
            if (jours.isEmpty || jours.last != j) jours.add(j);
          }
          final jourSel = jours.firstWhere(
            (j) => j.day == _jourChoisi,
            orElse: () => jours.first,
          );
          final duJour =
              heures.where((h) => _jour(h.heure) == jourSel).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SelecteurJour(
                jours: jours,
                selection: jourSel,
                onChoisir: (j) => setState(() => _jourChoisi = j.day),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: EspacementsApp.s2,
                  ),
                  itemCount: duJour.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _LigneHeure(prevision: duJour[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontal day chips ("Aujourd'hui", "Demain", "j mois").
class _SelecteurJour extends ConsumerWidget {
  final List<DateTime> jours;
  final DateTime selection;
  final ValueChanged<DateTime> onChoisir;

  const _SelecteurJour({
    required this.jours,
    required this.selection,
    required this.onChoisir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final n = ref.read(horlogeProvider)();
    final aujourdhui = DateTime(n.year, n.month, n.day);

    String libelle(DateTime j) {
      final delta = j.difference(aujourdhui).inDays;
      if (delta == 0) return l10n.jourAujourdhui;
      if (delta == 1) return l10n.jourDemain;
      return l10n.dateJourMois(j.day, _moisFr[j.month - 1]);
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s4,
          vertical: EspacementsApp.s2,
        ),
        children: [
          for (final j in jours) ...[
            ChoiceChip(
              label: Text(libelle(j)),
              selected: j == selection,
              onSelected: (_) => onChoisir(j),
            ),
            const SizedBox(width: EspacementsApp.s2),
          ],
        ],
      ),
    );
  }
}

/// One hour row: hour · temperature · rain probability + precipitation.
class _LigneHeure extends StatelessWidget {
  final PrevisionHoraire prevision;

  const _LigneHeure({required this.prevision});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accents = theme.extension<AccentsCarnet>()!;
    final l10n = AppLocalizations.of(context)!;
    final proba = (prevision.probabilitePluie * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s4,
        vertical: EspacementsApp.s3,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              l10n.meteoHeure(prevision.heure.hour),
              style: theme.textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.water_drop_outlined,
                    size: TaillesIconesApp.sm, color: accents.info),
                const SizedBox(width: EspacementsApp.s1),
                Text(
                  '$proba %',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (prevision.precipitationsMm > 0) ...[
                  const SizedBox(width: EspacementsApp.s2),
                  Text(
                    l10n.meteoPrecipMm(
                      prevision.precipitationsMm.toStringAsFixed(1),
                    ),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          Text(
            l10n.meteoTemp(prevision.temperature.round()),
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

const List<String> _moisFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
