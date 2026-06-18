import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart'; // EspacementsApp, RayonsApp, TaillesIconesApp
import '../../app/theme/theme_app.dart';
import '../../application/engine/generateur_resume_meteo.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/meteo_accueil_vue.dart';
import '../../application/state/meteo_detail_notifier.dart';
import '../../application/state/meteo_detail_vue.dart';
import '../../application/state/jour_meteo_vue.dart';
import '../../domain/value_objects/prevision_horaire.dart';
import '../../l10n/app_localizations.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

/// Full weather detail screen: station header, horizontal day selector,
/// horizontal hourly scroller, day summary, and task-explanation card.
///
/// Reached via `/accueil/meteo`. Watches [meteoDetailProvider] (ADR-0016 Lot 4).
class EcranMeteoDetail extends ConsumerStatefulWidget {
  const EcranMeteoDetail({super.key});

  @override
  ConsumerState<EcranMeteoDetail> createState() => _EcranMeteoDetailState();
}

class _EcranMeteoDetailState extends ConsumerState<EcranMeteoDetail> {
  /// Index of the currently selected day (0 = today).
  int _indexJour = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(meteoDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.maybeWhen(
            data: (v) => v.nomPotager.isNotEmpty ? v.nomPotager : l10n.meteoDetailTitre,
            orElse: () => l10n.meteoDetailTitre,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(EspacementsApp.s6),
            child: Text(l10n.meteoDetailErreur, textAlign: TextAlign.center),
          ),
        ),
        data: (vue) {
          if (!vue.disponible || vue.jours.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(EspacementsApp.s6),
                child: Text(l10n.meteoSansPosition, textAlign: TextAlign.center),
              ),
            );
          }

          final now = ref.read(horlogeProvider)();
          final aujourd = DateTime(now.year, now.month, now.day);
          final indexSel = _indexJour.clamp(0, vue.jours.length - 1);
          final jourSel = vue.jours[indexSel];

          String libelleJour(int i) {
            final j = vue.jours[i].date;
            final delta = DateTime(j.year, j.month, j.day).difference(aujourd).inDays;
            if (delta == 0) return l10n.jourAujourdhui;
            if (delta == 1) return l10n.jourDemain;
            return l10n.dateJourMois(j.day, _moisFr[j.month - 1]);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EnTeteStation(vue: vue),
                const SizedBox(height: EspacementsApp.s2),
                _SelecteurJours(
                  jours: vue.jours,
                  indexSel: indexSel,
                  onChoisir: (i) => setState(() => _indexJour = i),
                  libelleJour: libelleJour,
                ),
                const SizedBox(height: EspacementsApp.s2),
                _DefileurHoraire(heures: jourSel.heures),
                const Divider(height: EspacementsApp.s5),
                _ResumeJour(
                  vue: vue,
                  indexJourSel: indexSel,
                  libelleJour: libelleJour,
                ),
                const SizedBox(height: EspacementsApp.s4),
                _ExplicationTaches(vue: vue),
                const SizedBox(height: EspacementsApp.s7),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── _EnTeteStation ────────────────────────────────────────────────────────────

/// Station info banner: locality name · elevation · last-updated time.
class _EnTeteStation extends StatelessWidget {
  final MeteoDetailVue vue;
  const _EnTeteStation({required this.vue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final maj = vue.derniereMaj;
    final heureStr = '${maj.hour}h${maj.minute.toString().padLeft(2, '0')}';

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s4,
          vertical: EspacementsApp.s3,
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: TaillesIconesApp.sm, color: theme.colorScheme.primary),
            const SizedBox(width: EspacementsApp.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vue.nomStation != null)
                    Text(
                      l10n.meteoStation(vue.nomStation!),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  Row(
                    children: [
                      if (vue.elevation != null) ...[
                        Text(
                          '${vue.elevation!.round()} m',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          ' · ',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      Text(
                        l10n.meteoMajHeure(heureStr),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _SelecteurJours ───────────────────────────────────────────────────────────

/// Horizontal list of selectable day cards.
class _SelecteurJours extends StatelessWidget {
  final List<JourMeteoVue> jours;
  final int indexSel;
  final ValueChanged<int> onChoisir;
  final String Function(int) libelleJour;

  const _SelecteurJours({
    required this.jours,
    required this.indexSel,
    required this.onChoisir,
    required this.libelleJour,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
        itemCount: jours.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: EspacementsApp.s2),
          child: _CarteJour(
            jour: jours[i],
            selected: i == indexSel,
            onTap: () => onChoisir(i),
            libelle: libelleJour(i),
          ),
        ),
      ),
    );
  }
}

/// Single selectable day card.
class _CarteJour extends StatelessWidget {
  final JourMeteoVue jour;
  final bool selected;
  final VoidCallback onTap;
  final String libelle;

  const _CarteJour({
    required this.jour,
    required this.selected,
    required this.onTap,
    required this.libelle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final proba = (jour.probabilitePluie * 100).round();

    final bg = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerLow;
    final fg = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final fgSub = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: RayonsApp.brLg,
          border: selected
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s2,
          vertical: EspacementsApp.s3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              libelle,
              style: theme.textTheme.labelSmall?.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: EspacementsApp.s2),
            Icon(_iconeWmo(jour.weathercode),
                size: TaillesIconesApp.xl, color: fg),
            const SizedBox(height: EspacementsApp.s2),
            Text(
              l10n.meteoTemperatures(
                  jour.tempMin.round(), jour.tempMax.round()),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: fg),
            ),
            const SizedBox(height: EspacementsApp.s1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.air, size: 11, color: fgSub),
                const SizedBox(width: 2),
                Text(
                  '${jour.ventMaxKmh.round()} km/h',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: fgSub, fontSize: 10),
                ),
              ],
            ),
            if (proba >= 10) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_outlined, size: 11, color: fgSub),
                  const SizedBox(width: 2),
                  Text(
                    '$proba %',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: fgSub, fontSize: 10),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── _DefileurHoraire ──────────────────────────────────────────────────────────

/// Horizontal scroller of ~64 px compact hourly columns.
class _DefileurHoraire extends StatelessWidget {
  final List<PrevisionHoraire> heures;
  const _DefileurHoraire({required this.heures});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (heures.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s4,
          vertical: EspacementsApp.s3,
        ),
        child: Text(
          l10n.meteoDetailErreur,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
        itemCount: heures.length,
        itemBuilder: (_, i) => _ColonneHeure(h: heures[i]),
      ),
    );
  }
}

/// Single compact hourly column: hour · WMO icon · temperature · rain%.
class _ColonneHeure extends StatelessWidget {
  final PrevisionHoraire h;
  const _ColonneHeure({required this.h});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accents = theme.extension<AccentsCarnet>()!;
    final proba = (h.probabilitePluie * 100).round();

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.meteoHeure(h.heure.hour),
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EspacementsApp.s1),
          Icon(_iconeWmo(h.weathercode), size: TaillesIconesApp.md),
          const SizedBox(height: EspacementsApp.s1),
          Text(
            l10n.meteoTemp(h.temperature.round()),
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          if (proba > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop_outlined, size: 10, color: accents.info),
                Text(
                  '$proba %',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 9),
                ),
              ],
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── _ResumeJour ───────────────────────────────────────────────────────────────

/// Day-summary text block: short generated description of the selected day,
/// plus a J+1 outlook paragraph when today is selected.
class _ResumeJour extends StatelessWidget {
  final MeteoDetailVue vue;
  final int indexJourSel;
  final String Function(int) libelleJour;

  const _ResumeJour({
    required this.vue,
    required this.indexJourSel,
    required this.libelleJour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final jourSel = vue.jours[indexJourSel];

    // Use pre-computed text for today; re-generate for other days.
    final resumeSel = indexJourSel == 0
        ? vue.resumeAujourdhui
        : const GenerateurResumeMeteo().resumeJour(jourSel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(libelleJour(indexJourSel),
              style: theme.textTheme.titleSmall),
          const SizedBox(height: EspacementsApp.s1),
          Text(
            resumeSel,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          if (indexJourSel == 0 && vue.resumeDemain != null) ...[
            const SizedBox(height: EspacementsApp.s4),
            Text(l10n.jourDemain, style: theme.textTheme.titleSmall),
            const SizedBox(height: EspacementsApp.s1),
            Text(
              vue.resumeDemain!,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _ExplicationTaches ────────────────────────────────────────────────────────

/// Card explaining why the app generated the current tasks (verdict-based).
class _ExplicationTaches extends StatelessWidget {
  final MeteoDetailVue vue;
  const _ExplicationTaches({required this.vue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accents = theme.extension<AccentsCarnet>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconeVerdict(vue.verdictArrosage),
                size: TaillesIconesApp.lg,
                color: _couleurVerdict(vue.verdictArrosage, accents),
              ),
              const SizedBox(width: EspacementsApp.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.meteoPourquoiTaches,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: EspacementsApp.s1),
                    Text(
                      vue.explicationTaches,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconeVerdict(VerdictMeteo v) => switch (v) {
        VerdictMeteo.pluieAVenir     => Icons.umbrella_outlined,
        VerdictMeteo.solHumide       => Icons.water_drop_outlined,
        VerdictMeteo.arroserConseille => Icons.opacity,
        VerdictMeteo.clement         => Icons.eco_outlined,
      };

  Color _couleurVerdict(VerdictMeteo v, AccentsCarnet a) => switch (v) {
        VerdictMeteo.pluieAVenir      => a.info,
        VerdictMeteo.solHumide        => a.info,
        VerdictMeteo.arroserConseille => a.attention,
        VerdictMeteo.clement          => a.succes,
      };
}

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Maps a WMO weather interpretation code to the most appropriate
/// Material icon substitute (Phosphor Icons unavailable on Flutter 3.44.x).
IconData _iconeWmo(int code) {
  if (code == 0) return Icons.wb_sunny_outlined;
  if (code <= 2) return Icons.wb_cloudy_outlined;
  if (code == 3) return Icons.cloud_outlined;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code >= 51 && code <= 57) return Icons.grain;
  if (code >= 58 && code <= 67) return Icons.water_drop_outlined;
  if (code >= 71 && code <= 77) return Icons.ac_unit;
  if (code >= 80 && code <= 82) return Icons.water_drop_outlined;
  if (code == 85 || code == 86) return Icons.ac_unit;
  if (code >= 95 && code <= 99) return Icons.thunderstorm_outlined;
  return Icons.cloud_outlined;
}

const List<String> _moisFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
