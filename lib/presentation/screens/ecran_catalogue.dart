import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/state/catalogue_notifier.dart';
import '../../application/state/catalogue_vue.dart';
import '../../application/state/potager_notifier.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_plantation.dart';
import '../providers/ajout_plante_provider.dart';
import '../screens/ecran_selection_zone.dart';
import '../widgets/fiche_plante_detail.dart';
import '../widgets/libelles_enums.dart';
import '../widgets/vue_reseau_catalogue.dart';

/// Runs the "add a plant" flow for [fiche]: resolve the target zone (the pending
/// one, or let the user pick on the plan), open the plantation form pre-filled
/// with the plant, then confirm and jump to the zone on success.
Future<void> _ajouterPlante(
  BuildContext context,
  WidgetRef ref,
  FichePlante fiche,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  var zoneId = ref.read(ajoutPlanteProvider)?.zoneId;
  if (zoneId == null) {
    // Free browse: ask the user to pick a zone on the plan.
    zoneId = await selectionnerZonePourAjout(context);
    if (zoneId == null || !context.mounted) return;
  }

  final plantation = await ouvrirFormulairePlantation(
    context,
    zoneId,
    planteInitiale: fiche,
  );
  if (plantation == null) return; // form cancelled — keep any pending target.

  ref.read(ajoutPlanteProvider.notifier).effacer();
  ref.invalidate(potagerProvider);
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.snackPlanteAjoutee(fiche.nomLocalise('fr')))),
  );
  if (context.mounted) context.go(RoutesApp.zoneDetail(zoneId));
}

/// Tab 3 — **Catalogue**: knowledge base of plant sheets with search and a
/// category filter (docs/09 §5).
///
/// Two views (segmented toggle): **Fiches** (search + category chips + species
/// cards, each expandable to its varieties — ADR-0005) and **Réseau** (companion
/// constellation over the species). Both show species (mother sheets); varieties
/// appear only when a species is expanded in the list.
class EcranCatalogue extends ConsumerWidget {
  const EcranCatalogue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(catalogueProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navCatalogue)),
      body: vue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _EtatErreur(onReessayer: () => ref.invalidate(catalogueProvider)),
        data: (data) => _Contenu(vue: data),
      ),
    );
  }
}

class _Contenu extends ConsumerStatefulWidget {
  final CatalogueVue vue;

  const _Contenu({required this.vue});

  @override
  ConsumerState<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends ConsumerState<_Contenu> {
  bool _reseau = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vue = widget.vue;
    final cibleAjout = ref.watch(ajoutPlanteProvider);
    void ajouter(FichePlante fiche) => _ajouterPlante(context, ref, fiche);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cibleAjout != null)
          _BanniereAjout(
            zoneNom: cibleAjout.zoneNom,
            onAnnuler: () => ref.read(ajoutPlanteProvider.notifier).effacer(),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EspacementsApp.s4,
            EspacementsApp.s3,
            EspacementsApp.s4,
            EspacementsApp.s2,
          ),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.grid_view_outlined),
                label: Text(l10n.catalogueVueFiches),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.hub_outlined),
                label: Text(l10n.catalogueVueReseau),
              ),
            ],
            selected: {_reseau},
            onSelectionChanged: (s) => setState(() => _reseau = s.first),
          ),
        ),
        Expanded(
          child: _reseau
              ? VueReseauCatalogue(fiches: vue.toutesMeres, onAjouter: ajouter)
              : _VueFiches(vue: vue, onAjouter: ajouter),
        ),
      ],
    );
  }
}

/// The "Fiches" view: header count + search + category chips + result list.
class _VueFiches extends ConsumerWidget {
  final CatalogueVue vue;
  final void Function(FichePlante) onAjouter;

  const _VueFiches({required this.vue, required this.onAjouter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(catalogueProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EspacementsApp.s4,
            EspacementsApp.s2,
            EspacementsApp.s4,
            0,
          ),
          child: Text(
            l10n.catalogueNbPlantes(vue.total),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(EspacementsApp.s4),
          child: _BarreRecherche(
            valeur: vue.requete,
            onChanged: notifier.definirRequete,
          ),
        ),
        _ChipsCategories(
          courante: vue.categorie,
          onChoisir: notifier.definirCategorie,
        ),
        const SizedBox(height: EspacementsApp.s3),
        Expanded(
          child: vue.sansResultat
              ? _EtatVide(message: l10n.catalogueAucunResultat)
              : _Liste(groupes: vue.groupes, onAjouter: onAjouter),
        ),
      ],
    );
  }
}

/// Banner shown while an "add a plant" target zone is pending.
class _BanniereAjout extends StatelessWidget {
  final String zoneNom;
  final VoidCallback onAnnuler;

  const _BanniereAjout({required this.zoneNom, required this.onAnnuler});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EspacementsApp.s4,
          EspacementsApp.s2,
          EspacementsApp.s2,
          EspacementsApp.s2,
        ),
        child: Row(
          children: [
            Icon(Icons.add_location_alt_outlined,
                size: TaillesIconesApp.sm,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: EspacementsApp.s2),
            Expanded(
              child: Text(
                l10n.catalogueAjoutBanniere(zoneNom),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.catalogueAjoutAnnuler,
              color: theme.colorScheme.onPrimaryContainer,
              onPressed: onAnnuler,
            ),
          ],
        ),
      ),
    );
  }
}

/// Search field with a clear button.
class _BarreRecherche extends StatefulWidget {
  final String valeur;
  final ValueChanged<String> onChanged;

  const _BarreRecherche({required this.valeur, required this.onChanged});

  @override
  State<_BarreRecherche> createState() => _BarreRechercheState();
}

class _BarreRechercheState extends State<_BarreRecherche> {
  late final TextEditingController _controleur =
      TextEditingController(text: widget.valeur);

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controleur,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.catalogueRecherche,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controleur.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.catalogueEffacer,
                onPressed: () {
                  _controleur.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        border: const OutlineInputBorder(borderRadius: RayonsApp.brMd),
        isDense: true,
      ),
    );
  }
}

/// Horizontally scrollable category filter chips ("Tout" + each category).
class _ChipsCategories extends StatelessWidget {
  final CategoriePlante? courante;
  final ValueChanged<CategoriePlante?> onChoisir;

  const _ChipsCategories({required this.courante, required this.onChoisir});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
        children: [
          _Chip(
            libelle: l10n.catalogueTout,
            selectionne: courante == null,
            onTap: () => onChoisir(null),
          ),
          for (final c in ordreCategories) ...[
            const SizedBox(width: EspacementsApp.s2),
            _Chip(
              libelle: l10n.categorie(c),
              selectionne: courante == c,
              onTap: () => onChoisir(c),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String libelle;
  final bool selectionne;
  final VoidCallback onTap;

  const _Chip({
    required this.libelle,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ChoiceChip(
        label: Text(libelle),
        selected: selectionne,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Result list of species cards (each expandable to its varieties).
class _Liste extends StatelessWidget {
  final List<GroupeFiche> groupes;
  final void Function(FichePlante) onAjouter;

  const _Liste({required this.groupes, required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        0,
        EspacementsApp.s4,
        EspacementsApp.s6,
      ),
      itemCount: groupes.length,
      separatorBuilder: (_, _) => const SizedBox(height: EspacementsApp.s2),
      itemBuilder: (context, i) =>
          _CarteGroupe(groupe: groupes[i], onAjouter: onAjouter),
    );
  }
}

/// A species card with an expand control revealing its varieties (ADR-0005).
class _CarteGroupe extends StatefulWidget {
  final GroupeFiche groupe;
  final void Function(FichePlante) onAjouter;

  const _CarteGroupe({required this.groupe, required this.onAjouter});

  @override
  State<_CarteGroupe> createState() => _CarteGroupeState();
}

class _CarteGroupeState extends State<_CarteGroupe> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    final groupe = widget.groupe;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _CarteFiche(
            fiche: groupe.mere,
            onAjouter: widget.onAjouter,
            nbVarietes: groupe.varietes.length,
            ouvert: _ouvert,
            onToggle: groupe.aVarietes
                ? () => setState(() => _ouvert = !_ouvert)
                : null,
          ),
          if (_ouvert)
            for (final v in groupe.varietes)
              _LigneVariete(fiche: v, onAjouter: widget.onAjouter),
        ],
      ),
    );
  }
}

/// One species row: name, category, sun & water needs; trailing chevron, or an
/// expand toggle with the variety count when [onToggle] is set.
class _CarteFiche extends StatelessWidget {
  final FichePlante fiche;
  final void Function(FichePlante) onAjouter;
  final int nbVarietes;
  final bool ouvert;
  final VoidCallback? onToggle;

  const _CarteFiche({
    required this.fiche,
    required this.onAjouter,
    this.nbVarietes = 0,
    this.ouvert = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => afficherFichePlanteDetail(
        context,
        fiche,
        onAjouter: () => onAjouter(fiche),
      ),
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s3),
        child: Row(
          children: [
            Icon(Icons.eco_outlined, size: TaillesIconesApp.lg, color: theme.colorScheme.primary),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fiche.nomLocalise('fr'), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    l10n.categorie(fiche.categorie),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: EspacementsApp.s1),
                  Wrap(
                    spacing: EspacementsApp.s3,
                    children: [
                      _Meta(icone: Icons.wb_sunny_outlined, texte: l10n.exposition(fiche.besoins.soleil)),
                      _Meta(icone: Icons.water_drop_outlined, texte: l10n.besoinEau(fiche.besoins.eau)),
                    ],
                  ),
                ],
              ),
            ),
            if (onToggle != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(ouvert ? Icons.expand_less : Icons.expand_more),
                    tooltip: l10n.catalogueNbVarietes(nbVarietes),
                    onPressed: onToggle,
                  ),
                  Text(
                    '$nbVarietes',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              )
            else
              Icon(Icons.chevron_right, size: TaillesIconesApp.md, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// An indented variety row under its species, opening the variety's sheet.
class _LigneVariete extends StatelessWidget {
  final FichePlante fiche;
  final void Function(FichePlante) onAjouter;

  const _LigneVariete({required this.fiche, required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: InkWell(
        onTap: () => afficherFichePlanteDetail(
          context,
          fiche,
          onAjouter: () => onAjouter(fiche),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EspacementsApp.s6,
            EspacementsApp.s2,
            EspacementsApp.s3,
            EspacementsApp.s2,
          ),
          child: Row(
            children: [
              Icon(Icons.spa_outlined,
                  size: TaillesIconesApp.sm, color: theme.colorScheme.secondary),
              const SizedBox(width: EspacementsApp.s3),
              Expanded(
                child: Text(fiche.nomLocalise('fr'),
                    style: theme.textTheme.titleMedium),
              ),
              Icon(Icons.chevron_right,
                  size: TaillesIconesApp.md,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icone;
  final String texte;

  const _Meta({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: TaillesIconesApp.sm, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: EspacementsApp.s1),
        Text(
          texte,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EtatVide extends StatelessWidget {
  final String message;

  const _EtatVide({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: TaillesIconesApp.xl2, color: theme.colorScheme.secondary),
            const SizedBox(height: EspacementsApp.s4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

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
              l10n.catalogueErreurChargement,
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
