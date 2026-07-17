import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/state/detail_tache_notifier.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/etat_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_tache.dart';
import '../widgets/dialogue_confirmation.dart';
import '../widgets/libelles_enums.dart';

/// Task-detail screen (`/calendrier/tache/:id`): a full, revisitable view of a
/// single task with the actions the quick form does not surface.
///
/// From here the user can add or edit the task's **notes** (the "come back and
/// add details later" field), change its **priority**, **complete / reopen**,
/// **reschedule** or **cancel** it, jump to its **target** (zone / crop /
/// garden), and open the full edit form or delete it. The view-model
/// ([detailTacheProvider]) resolves the target's display name and route.
class EcranTacheDetail extends ConsumerWidget {
  final String tacheId;

  const EcranTacheDetail({super.key, required this.tacheId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(detailTacheProvider(tacheId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tacheDetailTitre),
        actions: [
          if (vue.value != null)
            PopupMenuButton<_ActionMenu>(
              onSelected: (a) => switch (a) {
                _ActionMenu.modifier => _modifier(context, ref, vue.value!.tache),
                _ActionMenu.supprimer =>
                  _supprimer(context, ref, vue.value!.tache),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _ActionMenu.modifier,
                  child: Text(l10n.actionModifier),
                ),
                PopupMenuItem(
                  value: _ActionMenu.supprimer,
                  child: Text(l10n.actionSupprimer),
                ),
              ],
            ),
        ],
      ),
      body: vue.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _EtatErreur(
          onReessayer: () => ref.invalidate(detailTacheProvider(tacheId)),
        ),
        data: (data) =>
            data == null ? const _Introuvable() : _Contenu(vue: data),
      ),
    );
  }

  Future<void> _modifier(BuildContext context, WidgetRef ref, Tache tache) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final modifiee = await ouvrirFormulaireTache(context, tacheInitiale: tache);
    if (modifiee == null) return;
    ref.invalidate(detailTacheProvider(tacheId));
    messenger.showSnackBar(SnackBar(content: Text(l10n.snackTacheModifiee)));
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref, Tache tache) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirme = await confirmerAction(
      context,
      titre: l10n.tacheSupprimerTitre,
      message: l10n.tacheSupprimerMessage(tache.titre),
      libelleConfirmer: l10n.actionSupprimer,
      destructif: true,
    );
    if (!confirme) return;
    await ref.read(detailTacheProvider(tacheId).notifier).supprimerTache();
    messenger.showSnackBar(SnackBar(content: Text(l10n.snackTacheSupprimee)));
    if (router.canPop()) router.pop();
  }
}

enum _ActionMenu { modifier, supprimer }

/// Scrollable detail body for a loaded task.
class _Contenu extends ConsumerWidget {
  final DetailTacheVue vue;

  const _Contenu({required this.vue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tache = vue.tache;
    final notifier = ref.read(detailTacheProvider(tache.id).notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      children: [
        // Header: gesture icon + title + type.
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tache.titre, style: theme.textTheme.titleLarge),
                  Text(
                    l10n.typeTache(tache.type),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s4),

        // State + priority chips.
        Wrap(
          spacing: EspacementsApp.s2,
          runSpacing: EspacementsApp.s2,
          children: [
            _Puce(
              icone: tache.estFaite
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              texte: l10n.etatTache(tache.etat),
            ),
            _Puce(
              icone: Icons.flag_outlined,
              texte: l10n.prioriteTache(tache.priorite),
            ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s5),

        // Target (zone / crop / garden), with navigation when available.
        if (vue.cibleNom != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(vue.cibleNom!),
              subtitle: Text(l10n.tacheDetailCible),
              trailing: vue.cibleRoute != null
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: vue.cibleRoute != null
                  ? () => context.go(vue.cibleRoute!)
                  : null,
            ),
          ),

        // Planned date + reschedule.
        Card(
          child: ListTile(
            leading: const Icon(Icons.event_outlined),
            title: Text(_formaterDate(l10n, tache.datePrevue)),
            subtitle: Text(l10n.tacheDetailDatePrevue),
            trailing: TextButton(
              onPressed: () => _reporter(context, ref, notifier, tache),
              child: Text(l10n.tacheReporter),
            ),
          ),
        ),

        // Origin (recurring reminder) — read-only, when applicable.
        if (tache.description != null && tache.description!.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s2),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EspacementsApp.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tacheDetailDescription,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(tache.description!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: EspacementsApp.s5),

        // Notes — the editable "add details later" field.
        _SectionNotes(
          notes: tache.notes,
          onEnregistrer: (v) => notifier.modifierNotes(v),
        ),
        const SizedBox(height: EspacementsApp.s5),

        // Priority picker.
        Text(l10n.tacheDetailPriorite, style: theme.textTheme.titleMedium),
        const SizedBox(height: EspacementsApp.s2),
        Wrap(
          spacing: EspacementsApp.s2,
          children: [
            for (final p in PrioriteTache.values)
              ChoiceChip(
                label: Text(l10n.prioriteTache(p)),
                selected: tache.priorite == p,
                onSelected: (sel) {
                  if (sel) notifier.changerPriorite(p);
                },
              ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s6),

        // Primary action: complete / reopen.
        FilledButton.icon(
          onPressed: () => notifier.basculerFait(),
          icon: Icon(tache.estFaite ? Icons.undo : Icons.check),
          label: Text(
              tache.estFaite ? l10n.tacheRouvrir : l10n.tacheMarquerFaite),
        ),
        const SizedBox(height: EspacementsApp.s2),
        // Cancel (unless already cancelled).
        if (tache.etat != EtatTache.annulee)
          OutlinedButton.icon(
            onPressed: () => _annuler(context, ref, notifier, tache),
            icon: const Icon(Icons.block_outlined),
            label: Text(l10n.tacheAnnuler),
          ),
      ],
    );
  }

  Future<void> _reporter(BuildContext context, WidgetRef ref,
      DetailTacheNotifier notifier, Tache tache) async {
    final base = tache.datePrevue;
    final choisie = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 2),
    );
    if (choisie != null) await notifier.reporter(choisie);
  }

  Future<void> _annuler(BuildContext context, WidgetRef ref,
      DetailTacheNotifier notifier, Tache tache) async {
    final l10n = AppLocalizations.of(context)!;
    final confirme = await confirmerAction(
      context,
      titre: l10n.tacheAnnulerTitre,
      message: l10n.tacheAnnulerMessage,
      libelleConfirmer: l10n.tacheAnnuler,
      destructif: true,
    );
    if (confirme) await notifier.annuler();
  }
}

/// Editable free-text notes block: shows the current notes and, on tap, an
/// inline editor with save / cancel.
class _SectionNotes extends StatefulWidget {
  final String? notes;
  final ValueChanged<String?> onEnregistrer;

  const _SectionNotes({required this.notes, required this.onEnregistrer});

  @override
  State<_SectionNotes> createState() => _SectionNotesState();
}

class _SectionNotesState extends State<_SectionNotes> {
  late final TextEditingController _controleur =
      TextEditingController(text: widget.notes ?? '');
  bool _edition = false;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.tacheDetailNotes,
                  style: theme.textTheme.titleMedium),
            ),
            if (!_edition)
              TextButton(
                onPressed: () => setState(() => _edition = true),
                child: Text(
                    widget.notes == null ? l10n.actionAjouter : l10n.actionModifier),
              ),
          ],
        ),
        const SizedBox(height: EspacementsApp.s2),
        if (_edition)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _controleur,
                minLines: 2,
                maxLines: 5,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.tacheDetailNotesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: EspacementsApp.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _controleur.text = widget.notes ?? '';
                        _edition = false;
                      });
                    },
                    child: Text(l10n.actionAnnuler),
                  ),
                  const SizedBox(width: EspacementsApp.s2),
                  FilledButton(
                    onPressed: () {
                      widget.onEnregistrer(_controleur.text);
                      setState(() => _edition = false);
                    },
                    child: Text(l10n.actionEnregistrer),
                  ),
                ],
              ),
            ],
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EspacementsApp.s3),
              child: Text(
                widget.notes ?? l10n.tacheDetailNotesVide,
                style: widget.notes == null
                    ? theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                    : theme.textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}

/// A small state / priority chip.
class _Puce extends StatelessWidget {
  final IconData icone;
  final String texte;

  const _Puce({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EspacementsApp.s3, vertical: EspacementsApp.s2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: TaillesIconesApp.sm),
          const SizedBox(width: 6),
          Text(texte, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Task no longer exists (e.g. just deleted).
class _Introuvable extends StatelessWidget {
  const _Introuvable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Text(l10n.tacheDetailIntrouvable, textAlign: TextAlign.center),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.accueilErreurChargement, textAlign: TextAlign.center),
            const SizedBox(height: EspacementsApp.s3),
            FilledButton.tonal(
              onPressed: onReessayer,
              child: Text(l10n.actionReessayer),
            ),
          ],
        ),
      ),
    );
  }
}

/// French month names (matching the weather/calendar screens' convention).
const List<String> _moisFr = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _formaterDate(AppLocalizations l10n, DateTime d) =>
    l10n.dateJourMoisAnnee(d.day, _moisFr[d.month - 1], d.year);
