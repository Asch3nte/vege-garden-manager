import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/acces_niveau_provider.dart';
import '../../application/state/accueil_notifier.dart';
import '../../application/state/parcelles_notifier.dart';
import '../../application/state/plantations_notifier.dart';
import '../../application/state/potager_notifier.dart';
import '../../application/state/potager_vue.dart';
import '../../application/state/prochaines_taches_zone_provider.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/statut_plantation.dart';
import '../../domain/enums/urgence_arrosage.dart';
import '../../domain/value_objects/conseil_arrosage.dart';
import '../providers/conseil_arrosage_plantation_provider.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_observation.dart';
import '../forms/formulaire_recolte.dart';
import '../forms/formulaire_zone.dart';
import '../providers/ajout_plante_provider.dart';
import '../widgets/dialogue_confirmation.dart';
import '../widgets/libelles_enums.dart';
import 'ecran_potager.dart' show couleurZone;

/// Detail of one garden zone (`ZoneDetail` in the `potager.jsx` mock-up), reached
/// by tapping a bed on the Potager plan.
///
/// Shows the zone's real data (name, type, surface, sun exposure, active crops)
/// and its actions: add a plant (→ catalogue), pull out / remove a crop, edit or
/// delete the zone. Deletes are **soft** (logical cascade), so history is kept.
/// Rich per-crop growth stages remain deferred (docs/15 §3).
class EcranZoneDetail extends ConsumerWidget {
  final String zoneId;

  const EcranZoneDetail({required this.zoneId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(potagerProvider);
    // Next pending task per crop — secondary data: if it is not ready yet the
    // crops still render immediately (empty map = no "next task" line shown).
    final prochaines =
        ref.watch(prochainesTachesZoneProvider(zoneId)).value ?? const {};

    return vue.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.potagerErreurChargement)),
      ),
      data: (data) {
        final index = data.zones.indexWhere((z) => z.id == zoneId);
        if (index < 0) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.zoneDetailIntrouvable)),
          );
        }
        final zone = data.zones[index];
        final potagerId = data.potagerId!;
        return _Detail(
          zone: zone,
          couleur: couleurZone(index),
          prochainesTaches: prochaines,
          onAjouterPlante: () {
            ref
                .read(ajoutPlanteProvider.notifier)
                .cibler(zoneId: zone.id, zoneNom: zone.nom);
            context.go(RoutesApp.catalogue);
          },
          onModifierZone: () => _modifierZone(context, ref, potagerId, zone.id),
          onSupprimerZone: () => _supprimerZone(context, ref, potagerId, zone),
          onArracher: (c) => _arracher(context, ref, zone.id, c),
          onSupprimerPlante: (c) => _supprimerPlante(context, ref, zone.id, c),
          onRecolter: (c) => _recolter(context, ref, c),
          onObserver: (c) => _observer(context, c),
        );
      },
    );
  }
}

/// Opens the zone in the edit form (pre-filled), then refreshes on save.
Future<void> _modifierZone(
  BuildContext context,
  WidgetRef ref,
  String potagerId,
  String zoneId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final parcelles = await ref.read(parcellesProvider(potagerId).future);
  final parcelle = parcelles.where((p) => p.id == zoneId).firstOrNull;
  if (parcelle == null || !context.mounted) return;

  final maj = await ouvrirFormulaireZone(
    context,
    potagerId,
    parcelleInitiale: parcelle,
  );
  if (maj == null) return;
  ref.invalidate(potagerProvider);
  messenger.showSnackBar(SnackBar(content: Text(l10n.snackZoneModifiee)));
}

/// Confirms then soft-deletes the zone (logical cascade), back to the plan.
Future<void> _supprimerZone(
  BuildContext context,
  WidgetRef ref,
  String potagerId,
  ZonePotager zone,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await confirmerAction(
    context,
    titre: l10n.zoneSupprimerTitre,
    message: l10n.zoneSupprimerMessage(zone.nom, zone.nombreCultures),
    libelleConfirmer: l10n.actionSupprimer,
    destructif: true,
  );
  if (!ok || !context.mounted) return;

  await ref.read(parcellesProvider(potagerId).notifier).supprimer(zone.id);
  ref.invalidate(potagerProvider);
  messenger.showSnackBar(SnackBar(content: Text(l10n.snackZoneSupprimee)));
  if (context.mounted) context.go(RoutesApp.potager);
}

/// Marks a crop as pulled out (`arrachee`): it leaves the active crops but stays
/// in the database as history.
Future<void> _arracher(
  BuildContext context,
  WidgetRef ref,
  String zoneId,
  CulturePotager culture,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final maintenant = ref.read(horlogeProvider)();
  final plantations = await ref.read(plantationsProvider(zoneId).future);
  final plantation =
      plantations.where((p) => p.id == culture.plantationId).firstOrNull;
  if (plantation == null) return;

  plantation.changerStatut(StatutPlantation.arrachee, dateFin: maintenant);
  await ref.read(plantationsProvider(zoneId).notifier).modifier(plantation);
  ref.invalidate(potagerProvider);
  messenger
      .showSnackBar(SnackBar(content: Text(l10n.snackPlanteArrachee(culture.nom))));
}

/// Confirms then soft-deletes a crop entirely (removes a mistaken entry).
Future<void> _supprimerPlante(
  BuildContext context,
  WidgetRef ref,
  String zoneId,
  CulturePotager culture,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await confirmerAction(
    context,
    titre: l10n.planteSupprimerTitre,
    message: l10n.planteSupprimerMessage(culture.nom),
    libelleConfirmer: l10n.actionSupprimer,
    destructif: true,
  );
  if (!ok) return;

  await ref.read(plantationsProvider(zoneId).notifier).supprimer(culture.plantationId);
  ref.invalidate(potagerProvider);
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.snackPlanteSupprimee(culture.nom))),
  );
}

/// Records a harvest for a crop, then refreshes the dashboard's season count.
Future<void> _recolter(
  BuildContext context,
  WidgetRef ref,
  CulturePotager culture,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final recolte = await ouvrirFormulaireRecolte(
    context,
    culture.plantationId,
    plante: culture.nom,
  );
  if (recolte == null) return;
  ref.invalidate(accueilProvider);
  messenger.showSnackBar(SnackBar(content: Text(l10n.snackRecolteCreee)));
}

/// Records an observation for a crop.
Future<void> _observer(BuildContext context, CulturePotager culture) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final obs = await ouvrirFormulaireObservation(
    context,
    culture.plantationId,
    plante: culture.nom,
  );
  if (obs == null) return;
  messenger.showSnackBar(SnackBar(content: Text(l10n.snackObservationCreee)));
}

/// The loaded detail body for a resolved [zone].
class _Detail extends StatelessWidget {
  final ZonePotager zone;
  final Color couleur;

  /// Next pending task per plantation id (absent when a crop has none).
  final Map<String, Tache> prochainesTaches;
  final VoidCallback onAjouterPlante;
  final VoidCallback onModifierZone;
  final VoidCallback onSupprimerZone;
  final void Function(CulturePotager) onArracher;
  final void Function(CulturePotager) onSupprimerPlante;
  final void Function(CulturePotager) onRecolter;
  final void Function(CulturePotager) onObserver;

  const _Detail({
    required this.zone,
    required this.couleur,
    required this.prochainesTaches,
    required this.onAjouterPlante,
    required this.onModifierZone,
    required this.onSupprimerZone,
    required this.onArracher,
    required this.onSupprimerPlante,
    required this.onRecolter,
    required this.onObserver,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(zone.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.zoneModifier,
            onPressed: onModifierZone,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.zoneSupprimer,
            onPressed: onSupprimerZone,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          EspacementsApp.s4,
          EspacementsApp.s4,
          EspacementsApp.s4,
          EspacementsApp.s6,
        ),
        children: [
          // Tinted hero with the zone's headline facts.
          Container(
            padding: const EdgeInsets.all(EspacementsApp.s4),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.all(RayonsApp.lg),
              border: Border.all(color: couleur.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.typeParcelle(zone.type),
                  style: theme.textTheme.labelMedium?.copyWith(color: couleur),
                ),
                const SizedBox(height: EspacementsApp.s2),
                Wrap(
                  spacing: EspacementsApp.s3,
                  runSpacing: EspacementsApp.s2,
                  children: [
                    _Fait(
                      icone: Icons.straighten,
                      texte: l10n.potagerSurfaceM2(
                        _formaterSurface(zone.surfaceM2),
                      ),
                    ),
                    _Fait(
                      icone: Icons.wb_sunny_outlined,
                      texte: l10n.exposition(zone.exposition),
                    ),
                    _Fait(
                      icone: Icons.local_florist_outlined,
                      texte: l10n.potagerNbCultures(zone.nombreCultures),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: EspacementsApp.s4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAjouterPlante,
              icon: const Icon(Icons.add),
              label: Text(l10n.zoneDetailAjouterPlante),
            ),
          ),
          const SizedBox(height: EspacementsApp.s5),
          Row(
            children: [
              Text(l10n.zoneDetailCultures, style: theme.textTheme.titleLarge),
              const SizedBox(width: EspacementsApp.s2),
              _Badge(texte: '${zone.nombreCultures}'),
            ],
          ),
          const SizedBox(height: EspacementsApp.s3),
          if (zone.cultures.isEmpty)
            Text(
              l10n.potagerNbCultures(0),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            for (var i = 0; i < zone.cultures.length; i++) ...[
              if (i > 0) const SizedBox(height: EspacementsApp.s2),
              _LigneCulture(
                culture: zone.cultures[i],
                couleur: couleur,
                prochaineTache: prochainesTaches[zone.cultures[i].plantationId],
                onRecolter: () => onRecolter(zone.cultures[i]),
                onObserver: () => onObserver(zone.cultures[i]),
                onArracher: () => onArracher(zone.cultures[i]),
                onSupprimer: () => onSupprimerPlante(zone.cultures[i]),
              ),
            ],
        ],
      ),
    );
  }
}

/// One labelled fact in the hero (icon + value).
class _Fait extends StatelessWidget {
  final IconData icone;
  final String texte;

  const _Fait({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone,
            size: TaillesIconesApp.sm, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: EspacementsApp.s1),
        Text(texte, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// One crop row: coloured dot + localized name + an actions menu (pull out /
/// remove).
class _LigneCulture extends ConsumerWidget {
  final CulturePotager culture;
  final Color couleur;

  /// The crop's next pending task, or `null` when it has none.
  final Tache? prochaineTache;
  final VoidCallback onRecolter;
  final VoidCallback onObserver;
  final VoidCallback onArracher;
  final VoidCallback onSupprimer;

  const _LigneCulture({
    required this.culture,
    required this.couleur,
    required this.prochaineTache,
    required this.onRecolter,
    required this.onObserver,
    required this.onArracher,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Observations are an intermediate+ feature (ADR-0009).
    final observationsDispo = ref.watch(accesNiveauProvider).observations;
    // Watering advice (ADR-0015) — silent on load/error (.value = null).
    final conseil = ref
        .watch(conseilArrosagePlantationProvider(culture.plantationId))
        .value;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s3,
        EspacementsApp.s1,
        EspacementsApp.s1,
        EspacementsApp.s1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(culture.nom, style: theme.textTheme.titleMedium),
                if (culture.etat != null) ...[
                  const SizedBox(height: EspacementsApp.s1),
                  Text(
                    l10n.libelleStade(culture.etat!.stade),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: EspacementsApp.s1),
                  ClipRRect(
                    borderRadius: RayonsApp.brSm,
                    child: LinearProgressIndicator(
                      value: culture.etat!.progression,
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: couleur,
                    ),
                  ),
                ],
                if (prochaineTache != null) ...[
                  const SizedBox(height: EspacementsApp.s2),
                  Row(
                    children: [
                      Icon(
                        iconeTypeTache(prochaineTache!.type),
                        size: TaillesIconesApp.sm,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: EspacementsApp.s2),
                      Expanded(
                        child: Text(
                          l10n.cultureProchaineTache(
                            prochaineTache!.titre,
                            _formaterDateCourte(prochaineTache!.datePrevue),
                          ),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
                if (conseil != null)
                  _LigneConseilArrosage(conseil: conseil, theme: theme, l10n: l10n),
              ],
            ),
          ),
          PopupMenuButton<_ActionCulture>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.cultureActions,
            onSelected: (action) => switch (action) {
              _ActionCulture.recolter => onRecolter(),
              _ActionCulture.observer => onObserver(),
              _ActionCulture.arracher => onArracher(),
              _ActionCulture.supprimer => onSupprimer(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ActionCulture.recolter,
                child: Row(
                  children: [
                    const Icon(Icons.shopping_basket_outlined,
                        size: TaillesIconesApp.sm),
                    const SizedBox(width: EspacementsApp.s2),
                    Text(l10n.cultureRecolter),
                  ],
                ),
              ),
              if (observationsDispo)
                PopupMenuItem(
                  value: _ActionCulture.observer,
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined,
                          size: TaillesIconesApp.sm),
                      const SizedBox(width: EspacementsApp.s2),
                      Text(l10n.cultureObserver),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: _ActionCulture.arracher,
                child: Row(
                  children: [
                    const Icon(Icons.cut_outlined, size: TaillesIconesApp.sm),
                    const SizedBox(width: EspacementsApp.s2),
                    Text(l10n.cultureArracher),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _ActionCulture.supprimer,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: TaillesIconesApp.sm,
                        color: theme.colorScheme.error),
                    const SizedBox(width: EspacementsApp.s2),
                    Text(l10n.actionSupprimer),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Per-crop actions in the detail menu.
enum _ActionCulture { recolter, observer, arracher, supprimer }

/// Small count badge.
class _Badge extends StatelessWidget {
  final String texte;

  const _Badge({required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Text(
        texte,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

/// Compact watering advice row (icon + label), shown inside [_LigneCulture].
///
/// Only rendered for actionable states (`arroserMaintenant`, `bientot`,
/// `pasNecessaire` + `pluiePrevue`). Silent otherwise (null conseil = no row).
class _LigneConseilArrosage extends StatelessWidget {
  final ConseilArrosage conseil;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _LigneConseilArrosage({
    required this.conseil,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final (icone, couleur, libelle) = switch (conseil.urgence) {
      UrgenceArrosage.arroserMaintenant => (
          Icons.water_drop,
          theme.colorScheme.error,
          l10n.conseilArroserMaintenant,
        ),
      UrgenceArrosage.bientot => (
          Icons.water_drop_outlined,
          theme.colorScheme.tertiary,
          l10n.conseilArroserBientot(conseil.joursAvantArrosage ?? 2),
        ),
      UrgenceArrosage.pasNecessaire when conseil.pluiePrevue => (
          Icons.water_outlined,
          theme.colorScheme.primary,
          l10n.conseilPluieAVenir,
        ),
      _ => (null, null, null),
    };

    if (libelle == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: EspacementsApp.s2),
      child: Row(
        children: [
          Icon(icone, size: TaillesIconesApp.sm, color: couleur),
          const SizedBox(width: EspacementsApp.s2),
          Expanded(
            child: Text(
              libelle,
              style: theme.textTheme.bodySmall?.copyWith(color: couleur),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a surface in m² without trailing ".0" for whole values.
String _formaterSurface(double m2) {
  return m2 == m2.roundToDouble()
      ? m2.toStringAsFixed(0)
      : m2.toStringAsFixed(1);
}

/// Short `dd/MM` date for the next-task line (the year is rarely useful there).
String _formaterDateCourte(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
