import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/providers/horloge_provider.dart';
import '../../application/state/equipements_notifier.dart';
import '../../application/state/parcelles_notifier.dart';
import '../../application/state/potager_notifier.dart';
import '../../domain/entities/equipement.dart';
import '../../domain/enums/etat_equipement.dart';
import '../../domain/enums/type_equipement.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_equipement.dart';
import '../glossaire/catalogue/outils.dart';
import '../glossaire/terme_cliquable.dart';
import '../glossaire/type_terme_glossaire.dart';
import '../widgets/dialogue_confirmation.dart';
import '../widgets/libelles_enums.dart';

/// Equipment list of the active garden (`Equipement`), reached from the Potager
/// header menu. An intermediate+ feature (ADR-0009, gated by `acces.equipements`
/// at the entry point).
///
/// Shows equipment still in service (with its type, condition, location and
/// derived agronomic effect) and, folded below, the retired ones kept for
/// history. The FAB registers a new equipment; each row can be edited, retired
/// (kept in history) or deleted (soft).
class EcranEquipements extends ConsumerWidget {
  const EcranEquipements({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final potagerId = ref.watch(potagerProvider).value?.potagerId;

    Future<void> ajouter() async {
      final cree = await ouvrirFormulaireEquipement(context, potagerId!);
      if (cree != null) _confirmer(ref, l10n.equipSnackCree);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.equipTitre)),
      floatingActionButton: potagerId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: ajouter,
              icon: const Icon(Icons.add),
              label: Text(l10n.equipAjouter),
            ),
      body: potagerId == null
          ? Center(child: Text(l10n.equipVide))
          : ref.watch(equipementsProvider(potagerId)).when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(l10n.potagerErreurChargement)),
                data: (equipements) => _Contenu(
                  potagerId: potagerId,
                  equipements: equipements,
                ),
              ),
    );
  }
}

/// The loaded body: in-service equipment, then the retired ones folded away.
class _Contenu extends ConsumerWidget {
  final String potagerId;
  final List<Equipement> equipements;

  const _Contenu({required this.potagerId, required this.equipements});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (equipements.isEmpty) {
      return _EtatVide(potagerId: potagerId);
    }

    // Zone names for the "location" line (transverse equipment has no zone).
    final parcelles =
        ref.watch(parcellesProvider(potagerId)).value ?? const [];
    final nomsZones = {for (final p in parcelles) p.id: p.nom};

    final enService = equipements.where((e) => e.estEnService).toList()
      ..sort((a, b) => b.dateInstallation.compareTo(a.dateInstallation));
    final retires = equipements.where((e) => !e.estEnService).toList()
      ..sort((a, b) => b.dateRetrait!.compareTo(a.dateRetrait!));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      children: [
        if (enService.isNotEmpty) ...[
          _EnTeteSection(
            titre: l10n.equipSectionEnService,
            compteur: enService.length,
          ),
          const SizedBox(height: EspacementsApp.s3),
          for (final e in enService) ...[
            _CarteEquipement(
              equipement: e,
              potagerId: potagerId,
              nomZone: e.parcelleId == null ? null : nomsZones[e.parcelleId],
            ),
            const SizedBox(height: EspacementsApp.s3),
          ],
        ],
        if (retires.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s2),
          Theme(
            // Remove the default divider lines of the expansion tile.
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: EspacementsApp.s3),
              title: _EnTeteSection(
                titre: l10n.equipSectionRetires,
                compteur: retires.length,
              ),
              children: [
                for (final e in retires) ...[
                  _CarteEquipement(
                    equipement: e,
                    potagerId: potagerId,
                    nomZone:
                        e.parcelleId == null ? null : nomsZones[e.parcelleId],
                  ),
                  const SizedBox(height: EspacementsApp.s3),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty state: an invitation to register the first equipment.
class _EtatVide extends ConsumerWidget {
  final String potagerId;

  const _EtatVide({required this.potagerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: EspacementsApp.s4),
            Text(l10n.equipVide,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: EspacementsApp.s2),
            Text(
              l10n.equipVideAide,
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

/// Section header: a title and a count badge.
class _EnTeteSection extends StatelessWidget {
  final String titre;
  final int compteur;

  const _EnTeteSection({required this.titre, required this.compteur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(titre, style: theme.textTheme.titleLarge),
        const SizedBox(width: EspacementsApp.s2),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: EspacementsApp.s2, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: const BorderRadius.all(RayonsApp.full),
          ),
          child: Text('$compteur',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        ),
      ],
    );
  }
}

/// One equipment card: type icon + name, condition chip, location, derived
/// effect chips, key dates, and an actions menu (edit / retire / delete).
class _CarteEquipement extends ConsumerWidget {
  final Equipement equipement;
  final String potagerId;

  /// Resolved zone name, or `null` when the equipment is transverse.
  final String? nomZone;

  const _CarteEquipement({
    required this.equipement,
    required this.potagerId,
    required this.nomZone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final effets = l10n.resumeEffet(equipement.effet());
    final retire = !equipement.estEnService;

    return Opacity(
      // Retired equipment is dimmed (kept for history).
      opacity: retire ? 0.6 : 1,
      child: Container(
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
            Icon(iconeTypeEquipement(equipement.type),
                color: theme.colorScheme.primary),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(equipement.nom,
                            style: theme.textTheme.titleMedium),
                      ),
                      _PuceEtat(etat: equipement.etat),
                    ],
                  ),
                  const SizedBox(height: EspacementsApp.s1),
                  // Type is a clickable term → its glossary page (one bible page
                  // per type; TypeEquipement.autre has none, shown plain). The
                  // location follows, muted.
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (equipement.type == TypeEquipement.autre)
                        Text(
                          l10n.typeEquipement(equipement.type),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        )
                      else
                        TermeCliquable(
                          idTerme: idOutilEquipement(equipement.type),
                          texte: l10n.typeEquipement(equipement.type),
                          type: TypeTermeGlossaire.outil,
                          style: theme.textTheme.bodySmall,
                        ),
                      Text(
                        ' · ${nomZone ?? l10n.equipTransverse}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (equipement.marqueModele != null) ...[
                    const SizedBox(height: EspacementsApp.s1),
                    Text(equipement.marqueModele!,
                        style: theme.textTheme.bodySmall),
                  ],
                  if (effets.isNotEmpty) ...[
                    const SizedBox(height: EspacementsApp.s2),
                    Wrap(
                      spacing: EspacementsApp.s2,
                      runSpacing: EspacementsApp.s1,
                      children: [for (final f in effets) _PuceEffet(texte: f)],
                    ),
                  ],
                  const SizedBox(height: EspacementsApp.s2),
                  _LignesDates(equipement: equipement),
                ],
              ),
            ),
            _MenuActions(
              equipement: equipement,
              potagerId: potagerId,
            ),
          ],
        ),
      ),
    );
  }
}

/// The key dates shown at the bottom of a card (install, planned replacement or
/// retirement).
class _LignesDates extends StatelessWidget {
  final Equipement equipement;

  const _LignesDates({required this.equipement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final style = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.equipInstalleLe(_formaterDate(equipement.dateInstallation)),
            style: style),
        if (equipement.dateRetrait != null)
          Text(l10n.equipRetireLe(_formaterDate(equipement.dateRetrait!)),
              style: style)
        else if (equipement.dateRemplacementPrevue != null)
          Text(
            l10n.equipRemplacerLe(
                _formaterDate(equipement.dateRemplacementPrevue!)),
            style: style,
          ),
      ],
    );
  }
}

/// Condition chip, tinted by severity.
class _PuceEtat extends StatelessWidget {
  final EtatEquipement etat;

  const _PuceEtat({required this.etat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final couleur = switch (etat) {
      EtatEquipement.neuf || EtatEquipement.bon => theme.colorScheme.primary,
      EtatEquipement.use => theme.colorScheme.tertiary,
      EtatEquipement.aRemplacer => theme.colorScheme.error,
      EtatEquipement.horsService => theme.colorScheme.onSurfaceVariant,
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: EspacementsApp.s2, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Text(l10n.etatEquipement(etat),
          style: theme.textTheme.labelSmall?.copyWith(color: couleur)),
    );
  }
}

/// A neutral effect chip (derived agronomic effect summary).
class _PuceEffet extends StatelessWidget {
  final String texte;

  const _PuceEffet({required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: EspacementsApp.s2, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(RayonsApp.full),
      ),
      child: Text(texte, style: theme.textTheme.labelSmall),
    );
  }
}

/// Per-equipment actions menu (edit / retire / delete).
class _MenuActions extends ConsumerWidget {
  final Equipement equipement;
  final String potagerId;

  const _MenuActions({required this.equipement, required this.potagerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_ActionEquipement>(
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.equipTitre,
      onSelected: (action) => switch (action) {
        _ActionEquipement.modifier => _modifier(context, ref),
        _ActionEquipement.retirer => _retirer(context, ref),
        _ActionEquipement.supprimer => _supprimer(context, ref),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ActionEquipement.modifier,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: TaillesIconesApp.sm),
              const SizedBox(width: EspacementsApp.s2),
              Text(l10n.actionModifier),
            ],
          ),
        ),
        if (equipement.estEnService)
          PopupMenuItem(
            value: _ActionEquipement.retirer,
            child: Row(
              children: [
                const Icon(Icons.archive_outlined, size: TaillesIconesApp.sm),
                const SizedBox(width: EspacementsApp.s2),
                Text(l10n.equipRetirer),
              ],
            ),
          ),
        PopupMenuItem(
          value: _ActionEquipement.supprimer,
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
    final maj = await ouvrirFormulaireEquipement(
      context,
      potagerId,
      equipementInitial: equipement,
    );
    if (maj == null) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.equipSnackModifie)));
  }

  Future<void> _retirer(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmerAction(
      context,
      titre: l10n.equipRetirerTitre,
      message: l10n.equipRetirerMessage(equipement.nom),
      libelleConfirmer: l10n.equipRetirer,
    );
    if (!ok) return;
    equipement.retirer(ref.read(horlogeProvider)());
    await ref.read(equipementsProvider(potagerId).notifier).modifier(equipement);
    messenger.showSnackBar(SnackBar(content: Text(l10n.equipSnackRetire)));
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmerAction(
      context,
      titre: l10n.equipSupprimerTitre,
      message: l10n.equipSupprimerMessage(equipement.nom),
      libelleConfirmer: l10n.actionSupprimer,
      destructif: true,
    );
    if (!ok) return;
    await ref.read(equipementsProvider(potagerId).notifier).supprimer(equipement.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.equipSnackSupprime)));
  }
}

/// Per-equipment actions in the card menu.
enum _ActionEquipement { modifier, retirer, supprimer }

/// Shows a transient confirmation, if a messenger is available.
void _confirmer(WidgetRef ref, String message) {
  final messenger = ScaffoldMessenger.maybeOf(ref.context);
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

/// `dd/MM/yyyy` date used on the cards.
String _formaterDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
