import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/providers/repository_providers.dart';
import '../../application/state/calendrier_notifier.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_tache.dart';
import '../providers/tache_detail_provider.dart';
import '../widgets/dialogue_confirmation.dart';
import '../widgets/libelles_enums.dart';

/// Full-screen detail of a single task (sub-route of the Calendar branch).
///
/// Shows the task's fields (type, status, due date, priority, target, notes)
/// and its actions: toggle done ↔ to-do, edit (the task form) and delete. Opened
/// by tapping a task card; the card's round pill still toggles completion in the
/// list without leaving it.
class EcranTacheDetail extends ConsumerWidget {
  final String tacheId;

  const EcranTacheDetail({super.key, required this.tacheId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(tacheDetailProvider(tacheId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tacheDetailTitre),
        actions: [
          async.maybeWhen(
            data: (vue) => vue == null
                ? const SizedBox.shrink()
                : PopupMenuButton<_Action>(
                    tooltip: l10n.actionsTache,
                    onSelected: (a) => switch (a) {
                      _Action.modifier => _modifier(context, ref, vue.tache),
                      _Action.supprimer => _supprimer(context, ref, vue.tache),
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: _Action.modifier,
                          child: Text(l10n.actionModifier)),
                      PopupMenuItem(
                          value: _Action.supprimer,
                          child: Text(l10n.actionSupprimer)),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Introuvable(message: l10n.tacheDetailIntrouvable),
        data: (vue) => vue == null
            ? _Introuvable(message: l10n.tacheDetailIntrouvable)
            : _Contenu(
                vue: vue,
                onBasculer: () => _basculer(ref, vue.tache),
              ),
      ),
    );
  }

  /// Toggles completion (check ↔ uncheck), persists, and refreshes the calendar.
  Future<void> _basculer(WidgetRef ref, Tache tache) async {
    if (tache.estFaite) {
      tache.rouvrir();
    } else {
      tache.marquerFaite(ref.read(horlogeProvider)());
    }
    await ref.read(tacheRepositoryProvider).sauvegarder(tache);
    ref.invalidate(tacheDetailProvider(tacheId));
    ref.invalidate(calendrierProvider);
  }

  Future<void> _modifier(BuildContext context, WidgetRef ref, Tache tache) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final modifiee = await ouvrirFormulaireTache(context, tacheInitiale: tache);
    if (modifiee == null) return;
    ref.invalidate(tacheDetailProvider(tacheId));
    ref.invalidate(calendrierProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.snackTacheModifiee)));
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref, Tache tache) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirme = await confirmerAction(
      context,
      titre: l10n.tacheSupprimerTitre,
      message: l10n.tacheSupprimerMessage(tache.titre),
      libelleConfirmer: l10n.actionSupprimer,
      destructif: true,
    );
    if (!confirme) return;
    await ref.read(tacheRepositoryProvider).supprimer(tache.id);
    ref.invalidate(calendrierProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.snackTacheSupprimee)));
    // Return to the calendar (the global back stack lands there anyway).
    if (context.mounted) context.go(RoutesApp.calendrier);
  }
}

enum _Action { modifier, supprimer }

class _Contenu extends StatelessWidget {
  final TacheDetailVue vue;
  final VoidCallback onBasculer;

  const _Contenu({required this.vue, required this.onBasculer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tache = vue.tache;
    final fait = tache.estFaite;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(EspacementsApp.s4),
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.all(RayonsApp.md),
                    ),
                    child: Icon(iconeTypeTache(tache.type),
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: EspacementsApp.s3),
                  Expanded(
                    child: Text(
                      tache.titre,
                      style: theme.textTheme.titleLarge?.copyWith(
                        decoration: fait ? TextDecoration.lineThrough : null,
                        color: fait ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EspacementsApp.s4),
              _EtatChip(tache: tache),
              const SizedBox(height: EspacementsApp.s4),
              _LigneInfo(
                icone: Icons.event_outlined,
                texte: l10n.tacheDetailDatePrevue(_formaterDate(tache.datePrevue)),
              ),
              _LigneInfo(
                icone: Icons.label_outline,
                texte: '${l10n.tacheDetailPriorite} : '
                    '${_libellePriorite(l10n, tache.priorite)}',
              ),
              _LigneInfo(
                icone: Icons.category_outlined,
                texte: '${l10n.tacheDetailConcerne} : '
                    '${_libelleCible(l10n, tache.cible)}'
                    '${vue.cibleNom != null ? ' · ${vue.cibleNom}' : ''}',
              ),
              _LigneInfo(
                icone: Icons.local_florist_outlined,
                texte: l10n.typeTache(tache.type),
              ),
              if ((tache.description ?? '').isNotEmpty) ...[
                const SizedBox(height: EspacementsApp.s4),
                _Bloc(titre: l10n.tacheDetailDescription, corps: tache.description!),
              ],
              if ((tache.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: EspacementsApp.s3),
                _Bloc(titre: l10n.tacheDetailNotes, corps: tache.notes!),
              ],
              if (tache.rappelOrigineId != null) ...[
                const SizedBox(height: EspacementsApp.s4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.autorenew,
                        size: TaillesIconesApp.sm,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: EspacementsApp.s2),
                    Expanded(
                      child: Text(
                        l10n.tacheDetailRappel,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(EspacementsApp.s4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBasculer,
                icon: Icon(fait ? Icons.undo : Icons.check),
                label: Text(fait
                    ? l10n.tacheDetailRouvrir
                    : l10n.tacheDetailMarquerFaite),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Status chip: "to do" (outlined) or "done on {date}" (filled).
class _EtatChip extends StatelessWidget {
  final Tache tache;

  const _EtatChip({required this.tache});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fait = tache.estFaite;
    final texte = fait
        ? l10n.tacheDetailEtatTerminee(
            _formaterDate(tache.dateRealisation ?? tache.datePrevue))
        : l10n.tacheDetailEtatAFaire;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: EspacementsApp.s3, vertical: EspacementsApp.s1),
        decoration: BoxDecoration(
          color: fait
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(RayonsApp.full),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fait ? Icons.check_circle : Icons.radio_button_unchecked,
              size: TaillesIconesApp.sm,
              color: fait ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: EspacementsApp.s2),
            Text(texte, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// One icon + text info row.
class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String texte;

  const _LigneInfo({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacementsApp.s2),
      child: Row(
        children: [
          Icon(icone,
              size: TaillesIconesApp.md, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(child: Text(texte, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// A titled text block (description / notes).
class _Bloc extends StatelessWidget {
  final String titre;
  final String corps;

  const _Bloc({required this.titre, required this.corps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: EspacementsApp.s1),
        Text(corps, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _Introuvable extends StatelessWidget {
  final String message;

  const _Introuvable({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

String _libellePriorite(AppLocalizations l10n, PrioriteTache p) => switch (p) {
      PrioriteTache.basse => l10n.prioriteBasse,
      PrioriteTache.normale => l10n.prioriteNormale,
      PrioriteTache.haute => l10n.prioriteHaute,
      PrioriteTache.urgente => l10n.prioriteUrgente,
    };

String _libelleCible(AppLocalizations l10n, CibleTache c) => switch (c) {
      CibleTache.potager => l10n.cibleTachePotager,
      CibleTache.parcelle => l10n.cibleTacheParcelle,
      CibleTache.plantation => l10n.cibleTachePlantation,
      CibleTache.equipement => l10n.cibleTacheEquipement,
    };

/// `dd/MM/yyyy` date (matches the app's other card dates).
String _formaterDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
