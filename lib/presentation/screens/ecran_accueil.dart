import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/couleurs_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../app/theme/theme_app.dart';
import '../../application/providers/service_providers.dart';
import '../../application/state/accueil_notifier.dart';
import '../../application/state/accueil_vue.dart';
import '../../application/state/meteo_accueil_notifier.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/capture_localisation.dart';
import '../widgets/libelles_enums.dart';
import '../widgets/position_potager_actions.dart';

/// Tab 1 — **Accueil** (dashboard): garden overview, today's tasks, experience
/// level, weather & season stats. Read-only, no creation actions (docs/09 §3).
///
/// Reimplemented from the `accueil-final.jsx` mock-up (direction B « Tableau
/// modulaire ») as Flutter widgets. Real data (active garden, zones, today's
/// tasks, experience level) comes from [accueilProvider]; weather, alerts and
/// season harvests are explicit placeholders until their reads/verdicts exist.
class EcranAccueil extends ConsumerWidget {
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(accueilProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccueil)),
      body: vue.when(
        // Keep showing data while it reloads (e.g. on tab re-entry) — no flash.
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _EtatErreur(onReessayer: () => ref.invalidate(accueilProvider)),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(accueilProvider),
          child: _Contenu(
            vue: data,
            // Jump to the zone detail on the Potager tab (#5); the global back
            // stack returns straight to the dashboard.
            onZoneTap: (id) => context.go(RoutesApp.zoneDetail(id)),
            onToggleTache: (t) =>
                ref.read(accueilProvider.notifier).basculerTache(t),
          ),
        ),
      ),
    );
  }
}

/// Scrollable dashboard body for a loaded [AccueilVue].
class _Contenu extends StatelessWidget {
  final AccueilVue vue;
  final void Function(String zoneId) onZoneTap;
  final void Function(Tache tache) onToggleTache;

  const _Contenu({
    required this.vue,
    required this.onZoneTap,
    required this.onToggleTache,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      children: [
        _LigneNiveau(niveau: vue.niveau, nombreZones: vue.nombreZones),
        const SizedBox(height: EspacementsApp.s4),
        const _CarteMeteo(),
        const SizedBox(height: EspacementsApp.s5),
        _SectionTaches(taches: vue.tachesDuJour, onToggle: onToggleTache),
        const SizedBox(height: EspacementsApp.s5),
        _GrilleStats(
          nombreAlertes: vue.nombreAlertes,
          nombreRecoltes: vue.nombreRecoltesSaison,
          statistiquesVisibles: vue.statistiquesVisibles,
        ),
        const SizedBox(height: EspacementsApp.s5),
        _SectionPotager(zones: vue.zones, onZoneTap: onZoneTap),
      ],
    );
  }
}

/// Experience-level pill + progress + zone count.
class _LigneNiveau extends StatelessWidget {
  final NiveauExperience niveau;
  final int nombreZones;

  const _LigneNiveau({required this.niveau, required this.nombreZones});

  /// Progress fraction shown in the pill, by level.
  double get _progression => switch (niveau) {
        NiveauExperience.debutant => 0.33,
        NiveauExperience.intermediaire => 0.66,
        NiveauExperience.expert => 1.0,
      };

  String _libelle(AppLocalizations l10n) => switch (niveau) {
        NiveauExperience.debutant => l10n.niveauDebutant,
        NiveauExperience.intermediaire => l10n.niveauIntermediaire,
        NiveauExperience.expert => l10n.niveauExpert,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacementsApp.s3,
            vertical: EspacementsApp.s2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.all(RayonsApp.full),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: TaillesIconesApp.sm, color: theme.colorScheme.primary),
              const SizedBox(width: EspacementsApp.s1),
              Text(_libelle(l10n), style: theme.textTheme.labelSmall),
              const SizedBox(width: EspacementsApp.s2),
              SizedBox(
                width: 42,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(RayonsApp.full),
                  child: LinearProgressIndicator(
                    value: _progression,
                    minHeight: 5,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.grid_view, size: TaillesIconesApp.sm, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: EspacementsApp.s1),
        Text(
          l10n.accueilNbZones(nombreZones),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Captures a position (GPS or region) and stores it on the active garden.
Future<void> _definirPosition(BuildContext context, WidgetRef ref) async {
  final loc = await ouvrirCaptureLocalisation(
    context,
    ref.read(geolocalisationServiceProvider),
  );
  if (loc != null) await enregistrerPositionPotager(ref, loc);
}

/// Weather card: today's temperatures + a garden-level watering verdict for the
/// active garden's position. Prompts to set a position when none is known.
class _CarteMeteo extends ConsumerWidget {
  const _CarteMeteo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accents = theme.extension<AccentsCarnet>()!;
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(meteoAccueilProvider);

    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final (IconData icone, Widget contenu, VoidCallback? onTap) = async.when(
      loading: () => (
        Icons.cloud_outlined,
        Text(l10n.accueilMeteoAVenir, style: muted),
        null,
      ),
      error: (_, _) => (
        Icons.cloud_off_outlined,
        Text(l10n.accueilMeteoAVenir, style: muted),
        null,
      ),
      data: (vue) {
        if (!vue.disponible) {
          return (
            Icons.location_off_outlined,
            InkWell(
              onTap: () => _definirPosition(context, ref),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.meteoSansPosition, style: muted)),
                  Icon(Icons.chevron_right,
                      size: TaillesIconesApp.md,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
            null,
          );
        }
        return (
          iconeVerdictMeteo(vue.verdict),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.meteoTemperatures(vue.tempMin.round(), vue.tempMax.round()),
                style: theme.textTheme.titleMedium,
              ),
              Text(l10n.verdictMeteo(vue.verdict), style: muted),
              if (vue.risqueGel)
                Padding(
                  padding: const EdgeInsets.only(top: EspacementsApp.s1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ac_unit,
                          size: TaillesIconesApp.sm, color: accents.info),
                      const SizedBox(width: EspacementsApp.s1),
                      Text(
                        l10n.meteoGel,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: accents.info),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Position known → the card opens the hourly weather detail (a sub-
          // route of Accueil; the global back stack returns to the dashboard).
          () => context.go(RoutesApp.accueilMeteo),
        );
      },
    );

    final carte = Container(
      padding: const EdgeInsets.all(EspacementsApp.s4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accents.info.withValues(alpha: 0.14),
          theme.colorScheme.surfaceContainer,
        ),
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        border: Border.all(color: accents.info.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icone, size: TaillesIconesApp.xl, color: accents.info),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(child: contenu),
          if (onTap != null)
            Icon(Icons.chevron_right,
                size: TaillesIconesApp.md,
                color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );

    if (onTap == null) return carte;
    return InkWell(
      onTap: onTap,
      borderRadius: RayonsApp.brLg,
      child: carte,
    );
  }
}

/// "Tasks of the day" labelled section with a card list.
class _SectionTaches extends StatelessWidget {
  final List<Tache> taches;
  final void Function(Tache tache) onToggle;

  const _SectionTaches({required this.taches, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final aFaire = taches.where((t) => !t.estFaite).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabelSection(texte: l10n.accueilTachesDuJour, compteur: aFaire),
        const SizedBox(height: EspacementsApp.s2),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s3),
            child: taches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s4),
                    child: Text(
                      l10n.accueilAucuneTache,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < taches.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _LigneTache(
                          tache: taches[i],
                          onToggle: () => onToggle(taches[i]),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// One task row: tappable to toggle completion; check indicator + title.
class _LigneTache extends StatelessWidget {
  final Tache tache;
  final VoidCallback onToggle;

  const _LigneTache({required this.tache, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fait = tache.estFaite;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s3),
        child: Row(
          children: [
            Icon(
              fait ? Icons.check_circle : Icons.radio_button_unchecked,
              size: TaillesIconesApp.lg,
              color: fait ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Text(
                tache.titre,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fait ? theme.colorScheme.onSurfaceVariant : null,
                  decoration: fait ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-tile stats grid: active weather alerts + season harvests / locked tile.
class _GrilleStats extends StatelessWidget {
  final int nombreAlertes;
  final int nombreRecoltes;
  final bool statistiquesVisibles;

  const _GrilleStats({
    required this.nombreAlertes,
    required this.nombreRecoltes,
    required this.statistiquesVisibles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accents = theme.extension<AccentsCarnet>()!;
    final l10n = AppLocalizations.of(context)!;

    // IntrinsicHeight so both tiles match the taller one, without forcing an
    // unbounded height inside the scroll view (a stretched Row would).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TuileStat(
              icone: Icons.warning_amber_rounded,
              couleur: accents.chaud,
              titre: l10n.accueilAlertes(nombreAlertes),
            ),
          ),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: statistiquesVisibles
                ? _TuileStat(
                    icone: Icons.shopping_basket_outlined,
                    couleur: CouleursApp.decoAubergine,
                    titre: l10n.accueilRecoltesSaison(nombreRecoltes),
                  )
                : _TuileVerrouillee(texte: l10n.accueilStatsVerrouillees),
          ),
        ],
      ),
    );
  }
}

/// A stat tile (icon + label).
class _TuileStat extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String titre;

  const _TuileStat({required this.icone, required this.couleur, required this.titre});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(EspacementsApp.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(icone, size: TaillesIconesApp.md, color: couleur),
          const SizedBox(width: EspacementsApp.s2),
          Expanded(
            child: Text(
              titre,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Locked stat tile (progressive disclosure below expert level).
class _TuileVerrouillee extends StatelessWidget {
  final String texte;

  const _TuileVerrouillee({required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(EspacementsApp.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        border: Border.all(
          color: CouleursApp.decoAubergine.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: TaillesIconesApp.md, color: CouleursApp.decoAubergine),
          const SizedBox(width: EspacementsApp.s2),
          Expanded(
            child: Text(
              texte,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Garden overview" labelled section with one tile per zone.
class _SectionPotager extends StatelessWidget {
  final List<ZoneApercu> zones;
  final void Function(String zoneId) onZoneTap;

  const _SectionPotager({required this.zones, required this.onZoneTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabelSection(texte: l10n.accueilApercuPotager),
        const SizedBox(height: EspacementsApp.s2),
        if (zones.isEmpty)
          Text(
            l10n.accueilAucuneZone,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Row(
            children: [
              for (var i = 0; i < zones.length; i++) ...[
                if (i > 0) const SizedBox(width: EspacementsApp.s2),
                Expanded(
                  child: _TuileZone(
                    zone: zones[i],
                    onTap: () => onZoneTap(zones[i].id),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// One garden-zone tile (coloured header band + name); taps to the zone detail.
class _TuileZone extends StatelessWidget {
  final ZoneApercu zone;
  final VoidCallback onTap;

  const _TuileZone({required this.zone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: RayonsApp.brMd,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CouleursApp.decoVertMoyen, CouleursApp.accentPrimaireClair],
              ),
              borderRadius: const BorderRadius.all(RayonsApp.md),
            ),
          ),
          const SizedBox(height: EspacementsApp.s1),
          Text(
            zone.nom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Section label with an optional count badge.
class _LabelSection extends StatelessWidget {
  final String texte;
  final int? compteur;

  const _LabelSection({required this.texte, this.compteur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(texte, style: theme.textTheme.titleLarge),
        if (compteur != null) ...[
          const SizedBox(width: EspacementsApp.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s2, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.all(RayonsApp.full),
            ),
            child: Text(
              '$compteur',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ],
    );
  }
}

/// Error state with a retry action.
class _EtatErreur extends StatelessWidget {
  final VoidCallback onReessayer;

  const _EtatErreur({required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: TaillesIconesApp.xl2, color: theme.colorScheme.error),
            const SizedBox(height: EspacementsApp.s4),
            Text(
              l10n.accueilErreurChargement,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: EspacementsApp.s4),
            FilledButton(onPressed: onReessayer, child: Text(l10n.actionReessayer)),
          ],
        ),
      ),
    );
  }
}
