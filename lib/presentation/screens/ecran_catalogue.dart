import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/router.dart';
import '../../app/theme/dimensions_app.dart';
import '../../application/providers/repository_providers.dart';
import '../../application/state/acces_niveau_provider.dart';
import '../../application/state/catalogue_notifier.dart';
import '../../application/state/preferences_notifier.dart';
import '../../application/state/catalogue_vue.dart';
import '../../application/state/contexte_climat.dart';
import '../../application/state/potager_notifier.dart';
import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../l10n/app_localizations.dart';
import '../forms/formulaire_plantation.dart';
import '../providers/ajout_plante_provider.dart';
import '../providers/vue_reseau_provider.dart';
import '../screens/ecran_selection_zone.dart';
import '../widgets/badge_perso.dart';
import '../widgets/bouton_favori.dart';
import '../widgets/carte_teaser_palier.dart';
import '../widgets/fiche_plante_detail.dart';
import '../widgets/langue_contexte.dart';
import '../widgets/libelles_enums.dart';
import '../widgets/vue_associations.dart';
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
    SnackBar(content: Text(l10n.snackPlanteAjoutee(fiche.nomLocalise(l10n.localeName)))),
  );
  if (context.mounted) context.go(RoutesApp.zoneDetail(zoneId));
}

/// Tab 3 — **Catalogue**: knowledge base of plant sheets with search and a
/// category filter.
///
/// Two views (segmented toggle): **Fiches** (search + category chips + species
/// cards, each expandable to its varieties) and **Réseau** (companion
/// constellation over the species). Both show species (mother sheets); varieties
/// appear only when a species is expanded in the list.
class EcranCatalogue extends ConsumerWidget {
  const EcranCatalogue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final vue = ref.watch(catalogueProvider);
    // The personal-sheet editor is an expert feature: the entry point
    // only appears once unlocked. Personal sheets still show, tagged, in the
    // catalogue list for every level.
    final fichesPersoDispo = ref.watch(accesNiveauProvider).fichesPerso;
    // The Réseau view draws every species: the favourites filter does not
    // apply there, so its toggle is hidden.
    final reseauActif = ref.watch(accesNiveauProvider).vueReseau &&
        ref.watch(vueReseauProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCatalogue),
        actions: [
          if (vue.value case final data? when !reseauActif)
            IconButton(
              icon: Icon(data.favorisSeuls
                  ? PhosphorIconsFill.heart
                  : PhosphorIconsRegular.heart),
              tooltip: data.favorisSeuls
                  ? l10n.catalogueToutesPlantes
                  : l10n.catalogueFavorisSeuls,
              onPressed: () => ref
                  .read(catalogueProvider.notifier)
                  .definirFavorisSeuls(!data.favorisSeuls),
            ),
          if (fichesPersoDispo)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.leaf),
              tooltip: l10n.fichesPersoOuvrir,
              onPressed: () => context.go(RoutesApp.fichesPerso),
            ),
        ],
      ),
      body: vue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            _EtatErreur(onReessayer: () => ref.invalidate(catalogueProvider)),
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
  bool _teaserFerme = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vue = widget.vue;
    final cibleAjout = ref.watch(ajoutPlanteProvider);
    // The "Réseau" association view is an intermediate+ feature:
    // hidden for beginners, who keep the Fiches view only.
    final vueReseauDispo = ref.watch(accesNiveauProvider).vueReseau;
    final reseau = ref.watch(vueReseauProvider);
    final reseauActif = vueReseauDispo && reseau;
    void ajouter(FichePlante fiche) => _ajouterPlante(context, ref, fiche);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cibleAjout != null)
          _BanniereAjout(
            zoneNom: cibleAjout.zoneNom,
            onAnnuler: () => ref.read(ajoutPlanteProvider.notifier).effacer(),
          ),
        if (vueReseauDispo)
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
                  icon: const Icon(PhosphorIconsRegular.squaresFour),
                  label: Text(l10n.catalogueVueFiches),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(PhosphorIconsRegular.graph),
                  label: Text(l10n.catalogueVueReseau),
                ),
              ],
              selected: {reseau},
              onSelectionChanged: (s) =>
                  ref.read(vueReseauProvider.notifier).choisir(s.first),
            ),
          ),
        Expanded(
          child: reseauActif
              ? VueReseauCatalogue(
                  fiches: vue.toutesMeres,
                  varietesDe: vue.varietesDe,
                  onAjouter: ajouter,
                )
              : _VueFiches(vue: vue, onAjouter: ajouter),
        ),
        // Level-up teaser for the locked Réseau view.
        if (!vueReseauDispo && !_teaserFerme)
          CarteTeaserPalier(
            icone: PhosphorIconsRegular.graph,
            feature: l10n.tutoVueReseauTitre,
            niveauRequis: NiveauExperience.intermediaire,
            onFermer: () => setState(() => _teaserFerme = true),
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
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
        if (vue.categorie != null && vue.familles.isNotEmpty) ...[
          const SizedBox(height: EspacementsApp.s2),
          _ChipsFamilles(
            familles: vue.familles,
            courante: vue.familleSelectionnee,
            onChoisir: notifier.definirFamille,
          ),
        ],
        const SizedBox(height: EspacementsApp.s3),
        Expanded(
          child: vue.sansResultat
              ? _EtatVide(
                  message: vue.favorisSeuls
                      ? l10n.catalogueAucunFavori
                      : l10n.catalogueAucunResultat)
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
            Icon(
              PhosphorIconsRegular.mapPinPlus,
              size: TaillesIconesApp.sm,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: EspacementsApp.s2),
            Expanded(
              child: Text(
                l10n.catalogueAjoutBanniere(zoneNom),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(PhosphorIconsRegular.x),
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
  late final TextEditingController _controleur = TextEditingController(
    text: widget.valeur,
  );

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
        prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
        suffixIcon: _controleur.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(PhosphorIconsRegular.x),
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

/// Second filter row: botanical families of the selected category ("Toutes" +
/// each family present among that category's species).
class _ChipsFamilles extends StatelessWidget {
  final List<FamilleBotanique> familles;
  final String? courante;
  final ValueChanged<String?> onChoisir;

  const _ChipsFamilles({
    required this.familles,
    required this.courante,
    required this.onChoisir,
  });

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
            libelle: l10n.catalogueToutesFamilles,
            selectionne: courante == null,
            onTap: () => onChoisir(null),
          ),
          for (final f in familles) ...[
            const SizedBox(width: EspacementsApp.s2),
            _Chip(
              libelle: f.nomLocalise(context.langue),
              selectionne: courante == f.id,
              onTap: () => onChoisir(f.id),
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

/// A species card with an expand control revealing its varieties.
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
/// expand toggle (arrow only — the variety count is dropped) when [onToggle]
/// is set.
class _CarteFiche extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Personal sheets are merged into the catalogue: tag them so
    // the user tells their own sheet from a built-in one at a glance.
    final estPerso =
        ref.watch(idsFichesPersonnellesProvider).value?.contains(fiche.id) ??
            false;

    return InkWell(
      onTap: () =>
          afficherFichePlanteDetail(context, fiche, onAjouter: onAjouter),
      child: Padding(
        padding: const EdgeInsets.all(EspacementsApp.s3),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.leaf,
              size: TaillesIconesApp.lg,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: EspacementsApp.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          fiche.nomLocalise(context.langue),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (estPerso) ...[
                        const SizedBox(width: EspacementsApp.s2),
                        const BadgePerso(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.categorie(fiche.categorie),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: EspacementsApp.s1),
                  Wrap(
                    spacing: EspacementsApp.s3,
                    children: [
                      _Meta(
                        icone: PhosphorIconsRegular.sun,
                        texte: l10n.exposition(fiche.besoins.soleil),
                      ),
                      _Meta(
                        icone: PhosphorIconsRegular.drop,
                        texte: l10n.besoinEau(fiche.besoins.eau),
                      ),
                      if (fiche.difficulte != null)
                        Semantics(
                          label: l10n.catalogueDifficulte(
                              l10n.difficulte(fiche.difficulte!)),
                          excludeSemantics: true,
                          child: _Meta(
                            icone: PhosphorIconsRegular.gauge,
                            texte: l10n.difficulte(fiche.difficulte!),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            BoutonFavori(ficheId: fiche.id),
            // One-tap access to the detailed Associations view of this species.
            IconButton(
              icon: const Icon(PhosphorIconsRegular.graph),
              tooltip: l10n.catalogueAssociations,
              onPressed: () async {
                final familles = await ref.read(famillesParIdProvider.future);
                final contexte = await ref.read(contexteClimatProvider.future);
                final climat = contexte == null || contexte.hemisphereSuppose
                    ? null
                    : contexte;
                if (!context.mounted) return;
                await afficherVueAssociations(
                  context,
                  fiche,
                  ref.read(catalogueProvider).value?.toutesMeres ??
                      const <FichePlante>[],
                  onAjouter: onAjouter,
                  familles: (brute) =>
                      familles[FamilleBotanique.normaliserCle(brute)],
                  hemisphere: climat?.hemisphere,
                  climat: climat?.climat,
                  // Derived suggestions appear from intermédiaire+,
                  // ranked by the user's weighting profile.
                  acces: ref.read(accesNiveauProvider),
                  profil: ref
                      .read(preferencesProvider)
                      .value
                      ?.ponderationAssociations,
                  // Tapping the preferences banner jumps to the weighting page.
                  onOuvrirPreferences: () =>
                      context.go(RoutesApp.plusPonderation),
                );
              },
            ),
            // The arrow only signals whether varieties exist (expandable) — the
            // count is dropped so every card's right side stays compact.
            // Both branches must take the *same* width: a default IconButton
            // reserves a 48px touch target, which would steal ~24px from the meta
            // Wrap on the left and push "Arrosage modéré" onto a second line only
            // for expandable cards. The toggle is therefore stripped to the bare
            // icon footprint (zero padding, no min constraints) so it matches the
            // plain chevron → the meta stays on one line on every card.
            if (onToggle != null)
              IconButton(
                icon: Icon(ouvert ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown),
                iconSize: TaillesIconesApp.md,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: l10n.catalogueNbVarietes(nbVarietes),
                onPressed: onToggle,
              )
            else
              Icon(
                PhosphorIconsRegular.caretRight,
                size: TaillesIconesApp.md,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: InkWell(
        onTap: () =>
            afficherFichePlanteDetail(context, fiche, onAjouter: onAjouter),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            EspacementsApp.s6,
            EspacementsApp.s2,
            EspacementsApp.s3,
            EspacementsApp.s2,
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIconsRegular.flowerLotus,
                size: TaillesIconesApp.sm,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: EspacementsApp.s3),
              Expanded(
                child: Text(
                  fiche.nomLocalise(context.langue),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: TaillesIconesApp.md,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
        Icon(
          icone,
          size: TaillesIconesApp.sm,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: EspacementsApp.s1),
        Text(
          texte,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
            PhosphorIcon(
              PhosphorIconsDuotone.magnifyingGlassMinus,
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
            Icon(
              PhosphorIconsRegular.warningCircle,
              size: TaillesIconesApp.xl2,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: EspacementsApp.s4),
            Text(
              l10n.catalogueErreurChargement,
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
