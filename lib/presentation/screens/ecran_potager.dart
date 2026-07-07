import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/couleurs_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../app/theme/theme_app.dart';
import '../../application/providers/repository_providers.dart';
import '../../application/state/acces_niveau_provider.dart';
import '../../application/state/accueil_notifier.dart';
import '../../application/state/contexte_climat.dart';
import '../../application/state/potager_notifier.dart';
import '../../application/state/potager_vue.dart';
import '../../application/state/potagers_notifier.dart';
import '../../application/state/saison_notifier.dart';
import '../../domain/entities/potager.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_potager.dart';
import '../forms/formulaire_zone.dart';
import '../widgets/astuce_post_onboarding.dart';
import '../widgets/dialogue_confirmation.dart';
import '../widgets/libelles_enums.dart';
import '../widgets/potager_actif_actions.dart';

/// Stable decorative colours assigned to zones by position, so each zone keeps a
/// consistent accent across the plan (mirrors the per-zone colour of the mock-up).
const List<Color> _couleursZones = [
  CouleursApp.decoVertProfond,
  CouleursApp.accentChaudClair,
  CouleursApp.decoAubergine,
  CouleursApp.decoVertMoyen,
  CouleursApp.decoBordeaux,
  CouleursApp.decoTerre,
];

/// Decorative colour of the zone at [index] in the plan (stable, cyclic).
Color couleurZone(int index) => _couleursZones[index % _couleursZones.length];

/// Tab 2 — **Potager**: a top-down *plan* of the active garden, one bed per zone
/// (docs/09 §4), reimplemented from the `potager.jsx` mock-up, **variant A**
/// (`PotagerGrille`): a grid of beds with the greenhouse spanning the full width.
///
/// Each bed shows the zone name, its crops and a drop marker when a task is due
/// today. Tapping a bed opens the zone detail. The spatial plan (variant B) needs
/// per-zone layout coordinates that the model does not carry yet (docs/15 §3).
class EcranPotager extends ConsumerWidget {
  const EcranPotager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(potagerProvider);
    final acces = ref.watch(accesNiveauProvider);

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
      appBar: AppBar(
        title: Text(l10n.navPotager),
        actions: [
          if (potagerId != null)
            PopupMenuButton<_ActionPotager>(
              onSelected: (a) => switch (a) {
                _ActionPotager.changer => _choisirPotager(context, ref),
                _ActionPotager.ajouter => _ajouterPotager(context, ref),
                _ActionPotager.modifier => _modifierPotager(context, ref),
                _ActionPotager.supprimer => _supprimerPotager(
                    context, ref, vue.value?.nomPotager ?? ''),
              },
              itemBuilder: (context) => [
                if (acces.multiPotager) ...[
                  PopupMenuItem(
                    value: _ActionPotager.changer,
                    child: Text(l10n.potagerChangerDe),
                  ),
                  PopupMenuItem(
                    value: _ActionPotager.ajouter,
                    child: Text(l10n.potagerAjouterAutre),
                  ),
                  const PopupMenuDivider(),
                ],
                PopupMenuItem(
                  value: _ActionPotager.modifier,
                  child: Text(l10n.potagerModifier),
                ),
                PopupMenuItem(
                  value: _ActionPotager.supprimer,
                  child: Text(l10n.potagerSupprimer),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: potagerId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: ajouterZone,
              icon: const Icon(Icons.add),
              label: Text(l10n.potagerCreerZone),
            ),
      body: vue.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            _EtatErreur(onReessayer: () => ref.invalidate(potagerProvider)),
        data: (data) {
          // One-off post-onboarding hint: nudge the user to tap a zone to add
          // plants (only meaningful once zones exist) — feedback #4.
          final astuce = ref.watch(astucePotagerZonesProvider);
          return Column(
            children: [
              if (astuce && data.zones.isNotEmpty)
                _BandeauAstuce(
                  message: l10n.astucePotagerZones,
                  onFermer: () =>
                      ref.read(astucePotagerZonesProvider.notifier).masquer(),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(potagerProvider),
                  child: _Contenu(vue: data),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Dismissable post-onboarding hint banner shown above the garden plan.
class _BandeauAstuce extends StatelessWidget {
  final String message;
  final VoidCallback onFermer;

  const _BandeauAstuce({required this.message, required this.onFermer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.fromLTRB(
          EspacementsApp.s4, EspacementsApp.s3, EspacementsApp.s2, EspacementsApp.s3),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              size: TaillesIconesApp.md, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: EspacementsApp.s2),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close,
                size: TaillesIconesApp.md, color: theme.colorScheme.onPrimaryContainer),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onFermer,
          ),
        ],
      ),
    );
  }
}

/// Shows a transient confirmation, if a messenger is available.
void _confirmer(WidgetRef ref, String message) {
  final messenger = ScaffoldMessenger.maybeOf(ref.context);
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

/// Garden-level actions in the Potager header menu.
enum _ActionPotager { changer, ajouter, modifier, supprimer }

/// Refreshes everything that depends on the active garden (plan, dashboard,
/// season, climate context) after it changed or was deleted.
void _rafraichirPotager(WidgetRef ref) {
  ref.invalidate(potagerProvider);
  ref.invalidate(accueilProvider);
  ref.invalidate(saisonProvider);
  ref.invalidate(contexteClimatProvider);
}

/// Opens a bottom sheet listing every garden (ADR-0009 multi-potager);
/// tapping one switches to it and refreshes the dependent views.
Future<void> _choisirPotager(BuildContext context, WidgetRef ref) async {
  final potagers = await ref.read(potagersProvider.future);
  final actif =
      await ref.read(potagerRepositoryProvider).obtenirPotagerActif();
  if (!context.mounted) return;
  final choisi = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        _FeuilleChoixPotager(potagers: potagers, actifId: actif?.id),
  );
  if (choisi == null || choisi == actif?.id) return;
  await definirPotagerActif(ref, choisi);
}

/// Creates a new garden and switches to it immediately.
Future<void> _ajouterPotager(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final cree = await ouvrirFormulairePotager(context);
  if (cree == null) return;
  await definirPotagerActif(ref, cree.id);
  _confirmer(ref, l10n.snackPotagerCree);
}

/// Opens the active garden in the edit form, then refreshes on save.
Future<void> _modifierPotager(BuildContext context, WidgetRef ref) async {
  final potager =
      await ref.read(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager == null || !context.mounted) return;
  final maj = await ouvrirFormulairePotager(context, potagerInitial: potager);
  if (maj == null) return;
  _rafraichirPotager(ref);
}

/// Confirms then soft-deletes the active garden (cascade), and refreshes.
Future<void> _supprimerPotager(
  BuildContext context,
  WidgetRef ref,
  String nom,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final potager =
      await ref.read(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager == null || !context.mounted) return;
  final ok = await confirmerAction(
    context,
    titre: l10n.potagerSupprimerTitre,
    message: l10n.potagerSupprimerMessage(nom),
    libelleConfirmer: l10n.actionSupprimer,
    destructif: true,
  );
  if (!ok) return;
  await ref.read(potagersProvider.notifier).supprimer(potager.id);
  _rafraichirPotager(ref);
  messenger.showSnackBar(SnackBar(content: Text(l10n.snackPotagerSupprime)));
}

/// Bottom sheet listing every garden (ADR-0009 multi-potager); returns the
/// tapped garden's id, or `null` if dismissed without a choice.
class _FeuilleChoixPotager extends StatelessWidget {
  final List<Potager> potagers;
  final String? actifId;

  const _FeuilleChoixPotager({required this.potagers, required this.actifId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                EspacementsApp.s4, 0, EspacementsApp.s4, EspacementsApp.s2),
            child: Text(l10n.potagerListeTitre, style: theme.textTheme.titleMedium),
          ),
          for (final p in potagers)
            ListTile(
              leading: Icon(
                p.id == actifId ? Icons.check_circle : Icons.circle_outlined,
                color: p.id == actifId
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              title: Text(p.nom),
              onTap: () => Navigator.of(context).pop(p.id),
            ),
          const SizedBox(height: EspacementsApp.s2),
        ],
      ),
    );
  }
}

/// Scrollable plan for a loaded [PotagerVue].
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
        PlanPotager(
          zones: vue.zones,
          onZoneTap: (id) => context.go(RoutesApp.zoneDetail(id)),
        ),
        const SizedBox(height: EspacementsApp.s4),
        const _Legende(),
      ],
    );
  }
}

/// The bed grid: greenhouse zones span the full width, the rest are laid out in
/// two columns, preserving the zones' display order.
///
/// Reusable: the Potager screen taps through to the zone detail, while the zone
/// picker (adding a plant) taps to pick a target — hence the [onZoneTap] hook.
class PlanPotager extends StatelessWidget {
  final List<ZonePotager> zones;
  final void Function(String zoneId) onZoneTap;

  const PlanPotager({required this.zones, required this.onZoneTap, super.key});

  @override
  Widget build(BuildContext context) {
    final lignes = <Widget>[];
    // Pending non-greenhouse beds, flushed two-by-two into a row.
    final paire = <Widget>[];

    void viderPaire() {
      if (paire.isEmpty) return;
      lignes.add(
        // IntrinsicHeight bounds the row's height so stretched beds share the
        // tallest's height (the row lives in an unbounded ListView).
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: paire[0]),
              const SizedBox(width: EspacementsApp.s2),
              // Keep a single bed at half width by pairing it with empty space.
              paire.length == 2 ? Expanded(child: paire[1]) : const Spacer(),
            ],
          ),
        ),
      );
      paire.clear();
    }

    for (var i = 0; i < zones.length; i++) {
      final zone = zones[i];
      final planche = _Planche(
        zone: zone,
        couleur: couleurZone(i),
        onTap: () => onZoneTap(zone.id),
      );
      if (zones[i].type == TypeParcelle.serre) {
        viderPaire();
        lignes.add(planche);
      } else {
        paire.add(planche);
        if (paire.length == 2) viderPaire();
      }
    }
    viderPaire();

    return Column(
      children: [
        for (var i = 0; i < lignes.length; i++) ...[
          if (i > 0) const SizedBox(height: EspacementsApp.s2),
          lignes[i],
        ],
      ],
    );
  }
}

/// One plan bed: tinted, colour-bordered card with the zone name, up to three
/// crop chips and a drop marker when a task is due today. Tapping it opens the
/// zone detail.
class _Planche extends StatelessWidget {
  final ZonePotager zone;
  final Color couleur;
  final VoidCallback onTap;

  const _Planche({
    required this.zone,
    required this.couleur,
    required this.onTap,
  });

  /// Crop chips shown on a bed before collapsing the rest into a "+N" chip.
  static const int _maxPuces = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final puces = <Widget>[
      for (final culture in zone.cultures.take(_maxPuces))
        _PuceCulture(texte: culture.nom, couleur: couleur),
      if (zone.cultures.length > _maxPuces)
        _PuceCulture(
          texte: '+${zone.cultures.length - _maxPuces}',
          couleur: couleur,
        ),
    ];

    return Material(
      color: couleur.withValues(alpha: 0.08),
      borderRadius: RayonsApp.brLg,
      child: InkWell(
        borderRadius: RayonsApp.brLg,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.all(EspacementsApp.s3),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(RayonsApp.lg),
            border: Border.all(color: couleur.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zone.nom,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (zone.aTacheAujourdhui)
                    _PastilleTache(key: Key('tache-${zone.id}')),
                ],
              ),
              const SizedBox(height: EspacementsApp.s2),
              if (puces.isEmpty)
                Text(
                  l10n.potagerNbCultures(0),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                Wrap(
                  spacing: EspacementsApp.s1,
                  runSpacing: EspacementsApp.s1,
                  children: puces,
                ),
              const SizedBox(height: EspacementsApp.s3),
              Text(
                '${l10n.potagerSurfaceM2(_formaterSurface(zone.surfaceM2))}'
                ' · ${l10n.exposition(zone.exposition)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small crop chip rendered inside a bed.
class _PuceCulture extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _PuceCulture({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Text(
        texte,
        style: theme.textTheme.labelSmall?.copyWith(color: couleur),
      ),
    );
  }
}

/// Drop marker shown on a bed (and in the legend) for "a task is due today".
class _PastilleTache extends StatelessWidget {
  const _PastilleTache({super.key});

  @override
  Widget build(BuildContext context) {
    final accents = Theme.of(context).extension<AccentsCarnet>()!;
    return Container(
      padding: const EdgeInsets.all(EspacementsApp.s1),
      decoration: BoxDecoration(
        color: accents.chaud.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.water_drop,
        size: TaillesIconesApp.sm,
        color: accents.chaud,
      ),
    );
  }
}

/// Plan legend: only the markers the plan actually renders are explained — the
/// zone colours are assigned by position (not by crop category), so a colour
/// legend would be misleading (decision: show what exists, docs/15 §3).
class _Legende extends StatelessWidget {
  const _Legende();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const _PastilleTache(),
        const SizedBox(width: EspacementsApp.s2),
        Text(
          l10n.potagerTacheDuJour,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
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
