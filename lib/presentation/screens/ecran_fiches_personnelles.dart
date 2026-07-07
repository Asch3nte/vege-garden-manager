import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/fiches_personnelles_notifier.dart';
import '../../domain/entities/fiche_plante_personnelle.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_fiche_personnelle.dart';
import '../widgets/dialogue_confirmation.dart';
import '../widgets/libelles_enums.dart';

/// Screen listing the user's own plant sheets (`FichePlantePersonnelle`),
/// reached from the Catalogue header. An expert feature (ADR-0009), gated by
/// `acces.fichesPerso` at the entry point.
///
/// Each sheet shows its common name, category and last-modified date, with an
/// actions menu (edit / delete). The FAB opens the creation form. Personal
/// sheets also appear, tagged, inside the catalogue itself.
class EcranFichesPersonnelles extends ConsumerWidget {
  const EcranFichesPersonnelles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> ajouter() async {
      final cree = await ouvrirFormulaireFichePersonnelle(context);
      if (cree != null) _confirmer(ref, l10n.fichesPersoSnackCreee);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fichesPersoTitre)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ajouter,
        icon: const Icon(Icons.add),
        label: Text(l10n.fichesPersoAjouter),
      ),
      body: ref.watch(fichesPersonnellesProvider).when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.potagerErreurChargement)),
            data: (fiches) =>
                fiches.isEmpty ? const _EtatVide() : _Liste(fiches: fiches),
          ),
    );
  }
}

/// The loaded list of sheets, most recently modified first (repo ordering).
class _Liste extends StatelessWidget {
  final List<FichePlantePersonnelle> fiches;

  const _Liste({required this.fiches});

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
        for (final f in fiches) ...[
          _CarteFiche(fiche: f),
          const SizedBox(height: EspacementsApp.s3),
        ],
      ],
    );
  }
}

/// Empty state: an invitation to author the first sheet.
class _EtatVide extends StatelessWidget {
  const _EtatVide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: EspacementsApp.s4),
            Text(l10n.fichesPersoVide,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: EspacementsApp.s2),
            Text(
              l10n.fichesPersoVideAide,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// One sheet card: common name + category, last-modified date, actions menu.
class _CarteFiche extends ConsumerWidget {
  final FichePlantePersonnelle fiche;

  const _CarteFiche({required this.fiche});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s3,
        EspacementsApp.s3,
        EspacementsApp.s1,
        EspacementsApp.s3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fiche.nomCommunFr, style: theme.textTheme.titleMedium),
                const SizedBox(height: EspacementsApp.s1),
                Text(
                  l10n.categorie(fiche.contenu.categorie),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: EspacementsApp.s2),
                Text(
                  l10n.fichesPersoModifieeLe(_formaterDate(fiche.dateModification)),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _MenuActions(fiche: fiche),
        ],
      ),
    );
  }
}

/// Per-sheet actions menu (edit / delete).
class _MenuActions extends ConsumerWidget {
  final FichePlantePersonnelle fiche;

  const _MenuActions({required this.fiche});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_ActionFiche>(
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.fichesPersoTitre,
      onSelected: (action) => switch (action) {
        _ActionFiche.modifier => _modifier(context, ref),
        _ActionFiche.supprimer => _supprimer(context, ref),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ActionFiche.modifier,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: TaillesIconesApp.sm),
              const SizedBox(width: EspacementsApp.s2),
              Text(l10n.actionModifier),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ActionFiche.supprimer,
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: TaillesIconesApp.sm, color: theme.colorScheme.error),
              const SizedBox(width: EspacementsApp.s2),
              Text(l10n.actionSupprimer),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _modifier(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final maj =
        await ouvrirFormulaireFichePersonnelle(context, ficheInitiale: fiche);
    if (maj == null) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.fichesPersoSnackModifiee)));
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmerAction(
      context,
      titre: l10n.fichesPersoSupprimerTitre,
      message: l10n.fichesPersoSupprimerMessage(fiche.nomCommunFr),
      libelleConfirmer: l10n.actionSupprimer,
      destructif: true,
    );
    if (!ok) return;
    await ref.read(fichesPersonnellesProvider.notifier).supprimer(fiche.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.fichesPersoSnackSupprimee)));
  }
}

/// Per-sheet actions in the card menu.
enum _ActionFiche { modifier, supprimer }

/// Shows a transient confirmation, if a messenger is available.
void _confirmer(WidgetRef ref, String message) {
  final messenger = ScaffoldMessenger.maybeOf(ref.context);
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

/// `dd/MM/yyyy` date used on the cards.
String _formaterDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
