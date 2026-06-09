import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/couleurs_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../app/theme/theme_app.dart';
import '../../application/state/potager_notifier.dart';
import '../../application/state/potager_vue.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_plantation.dart';
import '../forms/formulaire_potager.dart';
import '../forms/formulaire_zone.dart';

/// Stable decorative colours assigned to zones by position, so each zone keeps a
/// consistent accent in the list (mirrors the per-zone colour of the mock-up).
const List<Color> _couleursZones = [
  CouleursApp.decoVertProfond,
  CouleursApp.accentChaudClair,
  CouleursApp.decoAubergine,
  CouleursApp.decoVertMoyen,
  CouleursApp.decoBordeaux,
  CouleursApp.decoTerre,
];

/// Tab 2 — **Potager**: the active garden's zones, each with its crops and a
/// "task due today" marker (docs/09 §4).
///
/// Reimplemented from the `potager.jsx` mock-up, variant C (« Plan + liste »):
/// the zone list. The spatial/grid plans and the rich per-crop zone detail
/// (growth-stage bars, per-crop next task) are deferred — they need a growth
/// model and per-crop task wiring that do not exist yet.
class EcranPotager extends ConsumerWidget {
  const EcranPotager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(potagerProvider);

    // The FAB adds a zone to the active garden; only shown once a garden exists.
    final potagerId = vue.value?.potagerId;
    Future<void> ajouterZone() async {
      final cree = await ouvrirFormulaireZone(context, potagerId!);
      if (cree != null) {
        ref.invalidate(potagerProvider);
        _confirmer(ref, l10n.snackZoneCree);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navPotager)),
      floatingActionButton: potagerId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: ajouterZone,
              icon: const Icon(Icons.add),
              label: Text(l10n.potagerCreerZone),
            ),
      body: vue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            _EtatErreur(onReessayer: () => ref.invalidate(potagerProvider)),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(potagerProvider),
          child: _Contenu(vue: data),
        ),
      ),
    );
  }
}

/// Shows a transient confirmation, if a messenger is available.
void _confirmer(WidgetRef ref, String message) {
  final messenger = ScaffoldMessenger.maybeOf(ref.context);
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

/// Scrollable zone list for a loaded [PotagerVue].
class _Contenu extends ConsumerWidget {
  final PotagerVue vue;

  const _Contenu({required this.vue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // No garden at all: offer to create one.
    if (vue.potagerId == null) {
      return _EtatVide(
        message: l10n.potagerVideCta,
        action: FilledButton.icon(
          onPressed: () async {
            final cree = await ouvrirFormulairePotager(context);
            if (cree != null) {
              ref.invalidate(potagerProvider);
              _confirmer(ref, l10n.snackPotagerCree);
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.potagerCreer),
        ),
      );
    }

    // Garden exists but has no zone yet: the FAB handles adding one.
    if (vue.zones.isEmpty) {
      return _EtatVide(message: l10n.potagerVide);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      children: [
        Row(
          children: [
            Text(l10n.potagerZones, style: theme.textTheme.titleLarge),
            const SizedBox(width: EspacementsApp.s2),
            _Badge(texte: '${vue.nombreZones}'),
          ],
        ),
        const SizedBox(height: EspacementsApp.s3),
        for (var i = 0; i < vue.zones.length; i++) ...[
          if (i > 0) const SizedBox(height: EspacementsApp.s2),
          _LigneZone(
            zone: vue.zones[i],
            couleur: _couleursZones[i % _couleursZones.length],
            // Tapping a zone adds a plantation to it (no zone-detail screen yet).
            onAjouterPlantation: () async {
              final cree = await ouvrirFormulairePlantation(
                context,
                vue.zones[i].id,
              );
              if (cree != null) {
                ref.invalidate(potagerProvider);
                _confirmer(ref, l10n.snackPlantationCree);
              }
            },
          ),
        ],
      ],
    );
  }
}

/// One zone row: colour bar + name/crops + surface·exposure + task tag.
/// Tapping it adds a plantation to the zone (via [onAjouterPlantation]).
class _LigneZone extends StatelessWidget {
  final ZonePotager zone;
  final Color couleur;
  final VoidCallback onAjouterPlantation;

  const _LigneZone({
    required this.zone,
    required this.couleur,
    required this.onAjouterPlantation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: RayonsApp.brLg,
      child: InkWell(
        borderRadius: RayonsApp.brLg,
        onTap: onAjouterPlantation,
        child: Container(
          padding: const EdgeInsets.all(EspacementsApp.s3),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(RayonsApp.lg),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: couleur,
                    borderRadius: const BorderRadius.all(RayonsApp.full),
                  ),
                ),
                const SizedBox(width: EspacementsApp.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(zone.nom, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        zone.cultures.isEmpty
                            ? l10n.potagerNbCultures(0)
                            : zone.cultures.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.potagerSurfaceM2(_formaterSurface(zone.surfaceM2))}'
                        ' · ${_libelleExposition(l10n, zone.exposition)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: EspacementsApp.s2),
                _TagTache(aTacheAujourdhui: zone.aTacheAujourdhui),
                const SizedBox(width: EspacementsApp.s1),
                Icon(
                  Icons.chevron_right,
                  size: TaillesIconesApp.md,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Task status tag: "Tâche du jour" (warm) or "À jour" (primary).
class _TagTache extends StatelessWidget {
  final bool aTacheAujourdhui;

  const _TagTache({required this.aTacheAujourdhui});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accents = theme.extension<AccentsCarnet>()!;
    final l10n = AppLocalizations.of(context)!;
    final couleur = aTacheAujourdhui
        ? accents.chaud
        : theme.colorScheme.primary;
    final texte = aTacheAujourdhui
        ? l10n.potagerTacheDuJour
        : l10n.potagerZoneAJour;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Text(
        texte,
        style: theme.textTheme.labelSmall?.copyWith(color: couleur),
      ),
    );
  }
}

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
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Empty state (no active garden / no zone yet).
class _EtatVide extends StatelessWidget {
  final String message;
  final Widget? action;

  const _EtatVide({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_florist_outlined,
              size: TaillesIconesApp.xl2,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: EspacementsApp.s4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: EspacementsApp.s4),
              action!,
            ],
          ],
        ),
      ),
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
            Icon(
              Icons.error_outline,
              size: TaillesIconesApp.xl2,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: EspacementsApp.s4),
            Text(
              l10n.potagerErreurChargement,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: EspacementsApp.s4),
            FilledButton(
              onPressed: onReessayer,
              child: Text(l10n.actionReessayer),
            ),
          ],
        ),
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

/// French label for a sun exposure.
String _libelleExposition(AppLocalizations l10n, NiveauSoleil exposition) {
  return switch (exposition) {
    NiveauSoleil.pleinSoleil => l10n.expositionPleinSoleil,
    NiveauSoleil.miOmbre => l10n.expositionMiOmbre,
    NiveauSoleil.ombre => l10n.expositionOmbre,
  };
}
