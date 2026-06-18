import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/engine/moteur_derivation_associations.dart';
import '../../application/engine/scoreur_associations.dart';
import '../../application/engine/suggestion_association.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/critere_association.dart';
import '../../domain/enums/famille_effet_association.dart';
import '../../domain/enums/famille_effet_conflit.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/niveau_confiance.dart';
import '../../domain/enums/poids_association.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/sens_association.dart';
import '../../domain/services/acces_niveau.dart';
import '../../domain/services/resolveur_compagnonnage.dart';
import '../../domain/value_objects/profil_ponderation_associations.dart';
import '../../l10n/app_localizations.dart';
import 'explication_association.dart';
import 'fiche_plante_detail.dart';
import 'libelles_enums.dart';
import 'reseau/layout_vue_associations.dart';
import 'vue_reseau_catalogue.dart' show couleurCategorie;

/// Opens the **Associations** view of [centre]: a dedicated, detailed ego graph
/// of a single species — itself at the centre, its good companions on the left
/// half and the ones to avoid on the right half, **one node per species** (the
/// granular counterpart of the grouped "Réseau" constellation). Reached from the
/// Fiches list (ADR-0008). Companions are resolved over [catalogue] by the
/// shared service, so the split matches the catalogue everywhere.
///
/// Each association shows its typed **mechanism** and, when present, its
/// editorial **reason** (ADR-0010) — both resolved from the catalogue, never
/// invented. A bare pair (no mechanism) shows the name only.
/// Derived suggestions (ADR-0010) are added only when [acces] grants the network
/// view (intermédiaire+); [familles] lets the family-dependent rules fire
/// (repulsion / trap), and may be `null` for trait-based suggestions only.
/// Suggestions are **scored & ranked** by [profil] (ADR-0011): a family weighted
/// `ignore` is dropped, and only the top suggestions per side are shown (the rest
/// behind a "voir plus"). Curated associations always rank first and are never
/// pruned.
Future<void> afficherVueAssociations(
  BuildContext context,
  FichePlante centre,
  List<FichePlante> catalogue, {
  void Function(FichePlante)? onAjouter,
  AccesNiveau? acces,
  ResolveurFamille? familles,
  ProfilPonderationAssociations? profil,
  VoidCallback? onOuvrirPreferences,
  Hemisphere? hemisphere,
  TypeClimat? climat,
}) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).languageCode;
  const resolveur = ResolveurCompagnonnage();
  final comp = resolveur.resoudre(centre, catalogue);

  // Curated companions (Lot 1): always shown → ranked first via an infinite score.
  final bons = <_NoeudAssoc>[
    for (final c in comp.bonsDetailles)
      _NoeudAssoc(
        fiche: c.fiche,
        score: double.infinity,
        mecanisme: c.association.mecanisme == null
            ? null
            : l10n.mecanismeBenefice(c.association.mecanisme!),
        raison: c.association.raison(locale),
        sens: c.sens,
        bon: true,
      ),
  ];
  final aEviter = <_NoeudAssoc>[
    for (final c in comp.aEviterDetailles)
      _NoeudAssoc(
        fiche: c.fiche,
        score: double.infinity,
        mecanisme: c.association.mecanisme == null
            ? null
            : l10n.mecanismeConflit(c.association.mecanisme!),
        raison: c.association.raison(locale),
        sens: c.sens,
        bon: false,
      ),
  ];
  // Derived suggestions (Lot 3/4), gated by experience level (ADR-0009),
  // scored & weighted by the profile (ADR-0011).
  if (acces?.vueReseau ?? false) {
    _ajouterSuggestions(centre, catalogue, l10n, bons, aEviter, familles,
        profil ?? ProfilPonderationAssociations.defaut(),
        hemisphere: hemisphere, climat: climat);
  }

  // Conflict precedence: a pair is good **or** to-avoid, never both. When the
  // same species ends up on both sides (e.g. potato × artichoke: light layering
  // *and* nitrogen competition), the warning wins — drop it from the good side.
  final idsEviter = {for (final n in aEviter) n.fiche.id};
  bons.removeWhere((n) => idsEviter.contains(n.fiche.id));

  // Rank each side by score (curated first, then derived descending).
  bons.sort((a, b) => b.score.compareTo(a.score));
  aEviter.sort((a, b) => b.score.compareTo(a.score));

  return showDialog<void>(
    context: context,
    builder: (_) => _VueAssociations(
      centre: centre,
      bons: bons,
      aEviter: aEviter,
      onAjouter: onAjouter,
      profil: profil,
      onOuvrirPreferences: onOuvrirPreferences,
    ),
  );
}

/// Appends the engine's derived suggestions to [bons]/[aEviter], scored by
/// [profil] (ADR-0011): one node per (target, sense) keeping the best score,
/// dropping families weighted `ignore`, and skipping targets already shown as a
/// curated companion on the same side (curated precedence).
void _ajouterSuggestions(
  FichePlante centre,
  List<FichePlante> catalogue,
  AppLocalizations l10n,
  List<_NoeudAssoc> bons,
  List<_NoeudAssoc> aEviter,
  ResolveurFamille? familles,
  ProfilPonderationAssociations profil, {
  Hemisphere? hemisphere,
  TypeClimat? climat,
}) {
  const moteur = MoteurDerivationAssociations();
  const scoreur = ScoreurAssociations();
  final parId = {for (final f in catalogue) f.id: f};
  final dejaBons = {for (final n in bons) n.fiche.id};
  final dejaEviter = {for (final n in aEviter) n.fiche.id};

  final meilleurBenef = <String, SuggestionBenefique>{};
  final meilleurConflit = <String, SuggestionConflit>{};
  for (final s in moteur.suggestionsNouvelles(centre, catalogue,
      familles: familles, hemisphere: hemisphere, climat: climat)) {
    if (!scoreur.estRetenue(s, profil)) continue; // drops `ignore`d families
    switch (s) {
      case SuggestionBenefique():
        final e = meilleurBenef[s.cibleId];
        if (e == null || scoreur.score(s, profil) > scoreur.score(e, profil)) {
          meilleurBenef[s.cibleId] = s;
        }
      case SuggestionConflit():
        final e = meilleurConflit[s.cibleId];
        if (e == null || scoreur.score(s, profil) > scoreur.score(e, profil)) {
          meilleurConflit[s.cibleId] = s;
        }
    }
  }

  for (final s in meilleurBenef.values) {
    final f = parId[s.cibleId];
    if (f == null || dejaBons.contains(f.id)) continue;
    bons.add(_NoeudAssoc(
      fiche: f,
      score: scoreur.score(s, profil),
      mecanisme: l10n.mecanismeBenefice(s.mecanisme),
      suggere: true,
      confiance: l10n.confiance(s.confiance),
      niveauConfiance: s.confiance,
      criteres: s.criteres,
      sens: s.sens,
      bon: true,
    ));
  }
  for (final s in meilleurConflit.values) {
    final f = parId[s.cibleId];
    if (f == null || dejaEviter.contains(f.id)) continue;
    aEviter.add(_NoeudAssoc(
      fiche: f,
      score: scoreur.score(s, profil),
      mecanisme: l10n.mecanismeConflit(s.mecanisme),
      suggere: true,
      confiance: l10n.confiance(s.confiance),
      niveauConfiance: s.confiance,
      criteres: s.criteres,
      sens: s.sens,
      bon: false,
    ));
  }
}

/// A view-level node: a companion with its already-localised mechanism/reason,
/// its [score] (curated = infinite), and, for a derived one, the "suggested"
/// flag and confidence label.
class _NoeudAssoc {
  final FichePlante fiche;
  final double score;
  final String? mecanisme;
  final String? raison;
  final bool suggere;
  final String? confiance;

  /// Raw confidence level — kept alongside the localised [confiance] string so
  /// the suggestion-level filter can match without string comparison.
  final NiveauConfiance? niveauConfiance;

  /// Criteria the engine evaluated for a derived node (ADR-0014) — turned into
  /// the explicit factor list shown on the sheet.
  final Set<CritereAssociation> criteres;

  /// Direction seen from the centre (ADR-0012); `null` for the centre itself.
  final SensAssociation? sens;

  /// Good companion (true) vs to-avoid (false); `null` for the centre itself.
  final bool? bon;

  const _NoeudAssoc({
    required this.fiche,
    this.score = 0,
    this.mecanisme,
    this.raison,
    this.suggere = false,
    this.confiance,
    this.niveauConfiance,
    this.criteres = const {},
    this.sens,
    this.bon,
  });
}

/// A **group** of companions sharing the exact same relationship to the centre
/// (ADR-0013): same side, same direction, same suggested/curated nature, and the
/// same mechanism — or, for untyped curated pairs, the same free reason. Rendered
/// as one labelled cluster with a **single arrow** to the centre, so a shared
/// label (e.g. "Attire les pollinisateurs") is shown once instead of repeated on
/// every member.
class _GroupeAssoc {
  final List<_NoeudAssoc> membres;

  _GroupeAssoc(this.membres);

  /// The members all share these — read from the first one.
  _NoeudAssoc get _repr => membres.first;
  bool? get bon => _repr.bon;
  SensAssociation? get sens => _repr.sens;
  bool get suggere => _repr.suggere;
  String? get mecanisme => _repr.mecanisme;
  String? get confiance => _repr.confiance;

  /// Best member score — curated (infinite) groups sort first.
  double get score =>
      membres.fold(0.0, (m, n) => n.score > m ? n.score : m);
  bool get curate => score.isInfinite;

  /// Grouping key: side + direction + suggested + mechanism (or free reason when
  /// untyped). Untyped curated pairs with no reason fall into one "Autre" bucket.
  static String cleDe(_NoeudAssoc n) =>
      '${n.bon}|${n.sens}|${n.suggere}|${n.mecanisme ?? n.raison ?? ''}';

  /// Groups [noeuds] (kept in their incoming score order) by [cleDe].
  static List<_GroupeAssoc> grouper(List<_NoeudAssoc> noeuds) {
    final parCle = <String, List<_NoeudAssoc>>{};
    final ordre = <String>[];
    for (final n in noeuds) {
      final cle = cleDe(n);
      final liste = parCle[cle];
      if (liste == null) {
        parCle[cle] = [n];
        ordre.add(cle);
      } else {
        liste.add(n);
      }
    }
    return [for (final cle in ordre) _GroupeAssoc(parCle[cle]!)];
  }
}

class _VueAssociations extends StatefulWidget {
  final FichePlante centre;
  final List<_NoeudAssoc> bons;
  final List<_NoeudAssoc> aEviter;
  final void Function(FichePlante)? onAjouter;

  /// Weighting profile used to score the suggestions, surfaced as a banner so
  /// the user knows when a non-default profile skews the split (ADR-0013 §4).
  final ProfilPonderationAssociations? profil;

  /// Opens the weighting-profile page (navigation), or `null` to disable the
  /// banner tap.
  final VoidCallback? onOuvrirPreferences;

  const _VueAssociations({
    required this.centre,
    required this.bons,
    required this.aEviter,
    required this.onAjouter,
    required this.profil,
    required this.onOuvrirPreferences,
  });

  /// Max derived suggestions shown per side before "voir plus".
  static const int maxDerivesParCote = 5;

  @override
  State<_VueAssociations> createState() => _VueAssociationsState();
}

/// Filter options for the second (suggestion-level) filter row.
enum _FiltreSugg { tout, eleve, moyen, faible, horsMoteur }

class _VueAssociationsState extends State<_VueAssociations> {
  bool _tousAffiches = false;

  /// Direction filter (ADR-0012); `null` = all directions.
  SensAssociation? _filtre;

  /// Suggestion-level filter; defaults to [_FiltreSugg.tout].
  _FiltreSugg _filtreSugg = _FiltreSugg.tout;

  /// Zoom/pan transform; auto-fitted to the whole graph on first layout and
  /// whenever the displayed set changes (ADR-0013 §1).
  final TransformationController _transfo = TransformationController();

  /// Signature of the last set we auto-fitted, so a plain rebuild (e.g. opening
  /// a sheet) does not reset the user's manual zoom/pan.
  String? _signatureFit;

  @override
  void dispose() {
    _transfo.dispose();
    super.dispose();
  }

  /// Centres [canvas] in [viewport] at the scale that makes it fully visible
  /// (never zooming past 100 %).
  Matrix4 _matriceFit(Size viewport, Size canvas) {
    if (canvas.isEmpty || viewport.isEmpty) return Matrix4.identity();
    final s = math
        .min(viewport.width / canvas.width, viewport.height / canvas.height)
        .clamp(0.05, 1.0);
    final tx = (viewport.width - canvas.width * s) / 2;
    final ty = (viewport.height - canvas.height * s) / 2;
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  List<_NoeudAssoc> _filtrer(List<_NoeudAssoc> cote) {
    var r = _filtre == null ? cote : cote.where((n) => n.sens == _filtre).toList();
    r = switch (_filtreSugg) {
      _FiltreSugg.tout => r,
      _FiltreSugg.horsMoteur => r.where((n) => !n.suggere).toList(),
      _FiltreSugg.eleve =>
        r.where((n) => n.niveauConfiance == NiveauConfiance.eleve).toList(),
      _FiltreSugg.moyen =>
        r.where((n) => n.niveauConfiance == NiveauConfiance.moyen).toList(),
      _FiltreSugg.faible =>
        r.where((n) => n.niveauConfiance == NiveauConfiance.faible).toList(),
    };
    return r;
  }

  /// The side's **groups** capped at curated + N derived groups, unless expanded
  /// (ADR-0013 — capping now counts groups, not individual plants).
  List<_GroupeAssoc> _affiches(List<_GroupeAssoc> groupes) {
    if (_tousAffiches) return groupes;
    final nbCurated = groupes.where((g) => g.curate).length;
    final max = nbCurated + _VueAssociations.maxDerivesParCote;
    return groupes.length <= max ? groupes : groupes.sublist(0, max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final vide = widget.bons.isEmpty && widget.aEviter.isEmpty;
    final groupesBons = _GroupeAssoc.grouper(_filtrer(widget.bons));
    final groupesEviter = _GroupeAssoc.grouper(_filtrer(widget.aEviter));
    final bons = _affiches(groupesBons);
    final aEviter = _affiches(groupesEviter);
    final caches =
        (groupesBons.length - bons.length) + (groupesEviter.length - aEviter.length);
    final videAffiche = bons.isEmpty && aEviter.isEmpty;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.centre.nomLocalise('fr')),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: vide
              ? null
              : _BasAppBar(
                  profil: widget.profil,
                  onOuvrirPreferences: widget.onOuvrirPreferences,
                  filtre: _filtre,
                  onChoisir: (s) => setState(() => _filtre = s),
                  filtreSugg: _filtreSugg,
                  onChoisirSugg: (v) => setState(() => _filtreSugg = v),
                ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: (caches > 0 || _tousAffiches)
            ? _BoutonVoirPlus(
                caches: caches,
                tousAffiches: _tousAffiches,
                onPressed: () =>
                    setState(() => _tousAffiches = !_tousAffiches),
              )
            : null,
        body: videAffiche
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(EspacementsApp.s5),
                  child: Text(
                    l10n.reseauFocusAucun,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, c) {
                  final viewport = Size(c.maxWidth, c.maxHeight);
                  final geo = _GeoConstellation.calculer(bons, aEviter);
                  // Auto-fit when the displayed set changes (not on every rebuild,
                  // so opening a sheet keeps the user's zoom/pan). ADR-0013 §1.
                  final sig = '$_filtre|$_filtreSugg|$_tousAffiches|${geo.canvas}';
                  if (sig != _signatureFit) {
                    _signatureFit = sig;
                    _transfo.value = _matriceFit(viewport, geo.canvas);
                  }
                  return InteractiveViewer(
                    transformationController: _transfo,
                    constrained: false,
                    minScale: 0.05,
                    maxScale: 4,
                    boundaryMargin: const EdgeInsets.all(2000),
                    child: _Constellation(
                      geo: geo,
                      centre: widget.centre,
                      bons: bons,
                      aEviter: aEviter,
                      onTapNoeud: (n) {
                        // Resolve the rule's source/cible from the direction, then
                        // list every criterion that produced the association
                        // (ADR-0014). Curated nodes (no criteria) keep their reason.
                        final recoit = n.sens == SensAssociation.recoit;
                        final source = recoit ? n.fiche : widget.centre;
                        final cible = recoit ? widget.centre : n.fiche;
                        final facteurs = facteursAssociation(
                            l10n, n.criteres, source, cible);
                        afficherFichePlanteDetail(
                          context,
                          n.fiche,
                          onAjouter: widget.onAjouter,
                          contexte: n.bon == null
                              ? null
                              : ContexteAssociation(
                                  bon: n.bon!,
                                  mecanisme: n.mecanisme,
                                  raison: n.raison,
                                  suggere: n.suggere,
                                  confiance: n.confiance,
                                  facteurs: facteurs,
                                ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Floating toggle to reveal / hide the lower-scored derived suggestions
/// (ADR-0011 declutter).
class _BoutonVoirPlus extends StatelessWidget {
  final int caches;
  final bool tousAffiches;
  final VoidCallback onPressed;

  const _BoutonVoirPlus({
    required this.caches,
    required this.tousAffiches,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(tousAffiches ? Icons.expand_less : Icons.expand_more),
      label: Text(tousAffiches ? l10n.assocVoirMoins : l10n.assocVoirPlus(caches)),
    );
  }
}

/// AppBar `bottom`: a preferences banner above a side-by-side filter panel
/// (ADR-0013 §4) — direction (left) and suggestion level (right), each as a
/// dropdown so the layout stays compact.
class _BasAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ProfilPonderationAssociations? profil;
  final VoidCallback? onOuvrirPreferences;
  final SensAssociation? filtre;
  final void Function(SensAssociation?) onChoisir;
  final _FiltreSugg filtreSugg;
  final void Function(_FiltreSugg) onChoisirSugg;

  const _BasAppBar({
    required this.profil,
    required this.onOuvrirPreferences,
    required this.filtre,
    required this.onChoisir,
    required this.filtreSugg,
    required this.onChoisirSugg,
  });

  static const double _hauteurBandeau = 34;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_hauteurBandeau + _PanneauFiltres.hauteur);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BandeauPreferences(
          profil: profil,
          hauteur: _hauteurBandeau,
          onOuvrirPreferences: onOuvrirPreferences,
        ),
        _PanneauFiltres(
          filtre: filtre,
          onChoisir: onChoisir,
          filtreSugg: filtreSugg,
          onChoisirSugg: onChoisirSugg,
        ),
      ],
    );
  }
}

/// Single-line banner summarising the association weighting profile (ADR-0013
/// §4): the **tuned families only** (no verbose prefix), or "normales (par
/// défaut)". Tapping it jumps to the weighting page (ADR-0013 §7).
class _BandeauPreferences extends StatelessWidget {
  final ProfilPonderationAssociations? profil;
  final double hauteur;
  final VoidCallback? onOuvrirPreferences;

  const _BandeauPreferences({
    required this.profil,
    required this.hauteur,
    required this.onOuvrirPreferences,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final p = profil;
    final estDefaut = p == null || p.estDefaut;
    final accent = estDefaut
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.tertiary;

    // Default → a short hint; custom → just the tuned families (no prefix, so it
    // is not truncated for the part that matters — ADR-0013 §7).
    final String texte = estDefaut
        ? l10n.assocPrefsNormales
        : [
            for (final f in FamilleEffetAssociation.values)
              if (p.poids(f) != PoidsAssociation.normal)
                '${l10n.familleEffet(f)} (${l10n.poids(p.poids(f))})',
            for (final f in FamilleEffetConflit.values)
              if (p.poidsConflit(f) != PoidsAssociation.normal)
                '${l10n.familleEffetConflit(f)} (${l10n.poids(p.poidsConflit(f))})',
          ].join(', ');

    final contenu = Container(
      height: hauteur,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
      color: accent.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.tune, size: TaillesIconesApp.sm, color: accent),
          const SizedBox(width: EspacementsApp.s2),
          Expanded(
            child: Text(
              texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: accent),
            ),
          ),
          if (onOuvrirPreferences != null)
            Icon(Icons.chevron_right, size: TaillesIconesApp.sm, color: accent),
        ],
      ),
    );

    final ouvrir = onOuvrirPreferences;
    if (ouvrir == null) return contenu;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(); // close the fullscreen Associations view…
        ouvrir(); // …then navigate to the weighting page.
      },
      child: contenu,
    );
  }
}

/// Side-by-side filter panel: direction dropdown (left) and suggestion-level
/// dropdown (right).  Each column shows its current selection on a tappable
/// button; tapping opens a popup menu with all options.
class _PanneauFiltres extends StatelessWidget {
  final SensAssociation? filtre;
  final void Function(SensAssociation?) onChoisir;
  final _FiltreSugg filtreSugg;
  final void Function(_FiltreSugg) onChoisirSugg;

  const _PanneauFiltres({
    required this.filtre,
    required this.onChoisir,
    required this.filtreSugg,
    required this.onChoisirSugg,
  });

  static const double hauteur = 78;

  String _labelSens(AppLocalizations l10n, SensAssociation? s) => switch (s) {
        null => l10n.filtreTout,
        SensAssociation.donne => l10n.sensDonne,
        SensAssociation.recoit => l10n.sensRecoit,
        SensAssociation.mutuel => l10n.sensMutuel,
      };

  String _labelSugg(AppLocalizations l10n, _FiltreSugg s) => switch (s) {
        _FiltreSugg.tout => l10n.filtreTout,
        _FiltreSugg.eleve => l10n.assocFiltreEleve,
        _FiltreSugg.moyen => l10n.assocFiltreMoyen,
        _FiltreSugg.faible => l10n.assocFiltreFaible,
        _FiltreSugg.horsMoteur => l10n.assocHorsSuggestion,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget colonne({
      required String titre,
      required String label,
      required List<PopupMenuEntry<Object?>> items,
      required void Function(Object?) onSelected,
    }) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EspacementsApp.s3,
              vertical: EspacementsApp.s2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titre,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: EspacementsApp.s1),
                PopupMenuButton<Object?>(
                  onSelected: onSelected,
                  itemBuilder: (_) => items,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EspacementsApp.s3,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.all(RayonsApp.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return SizedBox(
      height: hauteur,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          colonne(
            titre: l10n.assocFiltrePrefixeAssoc,
            label: _labelSens(l10n, filtre),
            items: [
              PopupMenuItem(value: null, child: Text(l10n.filtreTout)),
              PopupMenuItem(
                  value: SensAssociation.donne, child: Text(l10n.sensDonne)),
              PopupMenuItem(
                  value: SensAssociation.recoit,
                  child: Text(l10n.sensRecoit)),
              PopupMenuItem(
                  value: SensAssociation.mutuel,
                  child: Text(l10n.sensMutuel)),
            ],
            onSelected: (v) => onChoisir(v as SensAssociation?),
          ),
          VerticalDivider(
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          colonne(
            titre: l10n.assocFiltrePrefixeSugg,
            label: _labelSugg(l10n, filtreSugg),
            items: [
              PopupMenuItem(
                  value: _FiltreSugg.tout, child: Text(l10n.filtreTout)),
              PopupMenuItem(
                  value: _FiltreSugg.eleve,
                  child: Text(l10n.assocFiltreEleve)),
              PopupMenuItem(
                  value: _FiltreSugg.moyen,
                  child: Text(l10n.assocFiltreMoyen)),
              PopupMenuItem(
                  value: _FiltreSugg.faible,
                  child: Text(l10n.assocFiltreFaible)),
              PopupMenuItem(
                  value: _FiltreSugg.horsMoteur,
                  child: Text(l10n.assocHorsSuggestion)),
            ],
            onSelected: (v) => onChoisirSugg(v as _FiltreSugg),
          ),
        ],
      ),
    );
  }
}

/// Shared dimensions of the cluster layout (used by both the geometry and the
/// rendering so they always agree).
class _DimGroupe {
  static const double rayonCentre = 26;
  static const double rayonMembre = 16;
  static const double largeurMembre = 92;
  static const double hauteurMembre = 70;
  static const int maxParRangee = 3;

  /// Min cluster width — wide enough for a full mechanism label (no truncation,
  /// ADR-0013 §4).
  static const double largeurMin = 144;

  /// Header band height (chip wrapped up to 3 lines + the suggestion/“hors
  /// suggestion” line) — generous so the (unconstrained) cluster never overlaps
  /// its neighbours.
  static const double hauteurEntete = 90;

  /// Inner padding of the rounded shape around a cluster (ADR-0013 §5).
  static const double paddingForme = 10;

  /// Free margin kept around the whole graph inside the canvas.
  static const double paddingCanvas = 80;

  static int colonnes(int m) => math.min(m, maxParRangee);
  static int rangees(int m) => (m / maxParRangee).ceil();

  /// Outer box (shape included) a group of [m] members occupies.
  static Size boite(int m) => Size(
        math.max(colonnes(m) * largeurMembre, largeurMin) + 2 * paddingForme,
        hauteurEntete + rangees(m) * hauteurMembre + 2 * paddingForme,
      );
}

/// A placed group: its [centre] (box centre) and outer [taille].
class _GeoGroupe {
  final Offset centre;
  final Size taille;
  const _GeoGroupe(this.centre, this.taille);
  Size get demi => Size(taille.width / 2, taille.height / 2);
}

/// Pre-computed geometry of the constellation: a [canvas] sized to the whole
/// content (so every node lies inside it and stays hit-testable, ADR-0013 §3),
/// the [centre] position and one [_GeoGroupe] per side.
class _GeoConstellation {
  final Size canvas;
  final Offset centre;
  final List<_GeoGroupe> bons;
  final List<_GeoGroupe> aEviter;

  const _GeoConstellation({
    required this.canvas,
    required this.centre,
    required this.bons,
    required this.aEviter,
  });

  static _GeoConstellation calculer(
    List<_GroupeAssoc> bons,
    List<_GroupeAssoc> aEviter,
  ) {
    // Uniform spacing box = the largest cluster, so the no-overlap ego layout
    // (ADR-0012) keeps its guarantee despite variable cluster sizes.
    final tous = [...bons, ...aEviter];
    var maxL = _DimGroupe.largeurMin, maxH = _DimGroupe.hauteurEntete;
    for (final g in tous) {
      final b = _DimGroupe.boite(g.membres.length);
      maxL = math.max(maxL, b.width);
      maxH = math.max(maxH, b.height);
    }
    // Lay out in a large virtual zone, then crop to the real bounding box.
    final res = const LayoutVueAssociations().calculer(
      nbBons: bons.length,
      nbAEviter: aEviter.length,
      tailleNoeud: Size(maxL, maxH),
      zone: const Size(4000, 4000),
    );

    final boites = <(Offset, Size)>[
      (res.centre, const Size(_DimGroupe.rayonCentre * 2, _DimGroupe.rayonCentre * 2)),
      for (var k = 0; k < bons.length; k++)
        (res.bons[k], _DimGroupe.boite(bons[k].membres.length)),
      for (var k = 0; k < aEviter.length; k++)
        (res.aEviter[k], _DimGroupe.boite(aEviter[k].membres.length)),
    ];
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final (p, s) in boites) {
      minX = math.min(minX, p.dx - s.width / 2);
      minY = math.min(minY, p.dy - s.height / 2);
      maxX = math.max(maxX, p.dx + s.width / 2);
      maxY = math.max(maxY, p.dy + s.height / 2);
    }
    const pad = _DimGroupe.paddingCanvas;
    final decalage = Offset(pad - minX, pad - minY);
    final canvas = Size(maxX - minX + 2 * pad, maxY - minY + 2 * pad);

    return _GeoConstellation(
      canvas: canvas,
      centre: res.centre + decalage,
      bons: [
        for (var k = 0; k < bons.length; k++)
          _GeoGroupe(res.bons[k] + decalage,
              _DimGroupe.boite(bons[k].membres.length)),
      ],
      aEviter: [
        for (var k = 0; k < aEviter.length; k++)
          _GeoGroupe(res.aEviter[k] + decalage,
              _DimGroupe.boite(aEviter[k].membres.length)),
      ],
    );
  }
}

/// The radial ego layout: a single arrow from the centre to each cluster, and
/// the clusters themselves (ADR-0013). Geometry is pre-computed in [geo].
class _Constellation extends StatelessWidget {
  final _GeoConstellation geo;
  final FichePlante centre;
  final List<_GroupeAssoc> bons;
  final List<_GroupeAssoc> aEviter;
  final void Function(_NoeudAssoc) onTapNoeud;

  const _Constellation({
    required this.geo,
    required this.centre,
    required this.bons,
    required this.aEviter,
    required this.onTapNoeud,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Width is fixed (drives wrapping & the shape width); height is left to the
    // content so a slightly taller cluster never overflows (ADR-0013 §1 fix).
    // The box estimate stays generous so spacing/arrows keep no-overlap.
    Widget groupe(_GroupeAssoc g, _GeoGroupe geoG, Color accent) => Positioned(
          left: geoG.centre.dx - geoG.taille.width / 2,
          top: geoG.centre.dy - geoG.taille.height / 2,
          width: geoG.taille.width,
          child: _GroupeWidget(
            groupe: g,
            accent: accent,
            onTapMembre: onTapNoeud,
          ),
        );

    // One edge per cluster; the painter trims the far end to the shape's edge so
    // the arrowhead lands on the coloured border, never on a bubble (ADR-0013).
    _Arete arete(_GroupeAssoc g, _GeoGroupe geoG) => (
          pos: geoG.centre,
          sens: g.sens,
          demi: Size(geoG.taille.width / 2 - _DimGroupe.paddingForme,
              geoG.taille.height / 2 - _DimGroupe.paddingForme),
        );

    return SizedBox(
      width: geo.canvas.width,
      height: geo.canvas.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: geo.canvas,
            painter: _Peintre(
              centre: geo.centre,
              bons: [
                for (var k = 0; k < bons.length; k++) arete(bons[k], geo.bons[k]),
              ],
              eviter: [
                for (var k = 0; k < aEviter.length; k++)
                  arete(aEviter[k], geo.aEviter[k]),
              ],
              couleurBon: theme.colorScheme.primary,
              couleurEviter: theme.colorScheme.error,
              rayonCentre: _DimGroupe.rayonCentre,
            ),
          ),
          for (var k = 0; k < bons.length; k++)
            groupe(bons[k], geo.bons[k], theme.colorScheme.primary),
          for (var k = 0; k < aEviter.length; k++)
            groupe(aEviter[k], geo.aEviter[k], theme.colorScheme.error),
          Positioned(
            left: geo.centre.dx - _DimGroupe.largeurMembre / 2,
            top: geo.centre.dy - _DimGroupe.rayonCentre,
            width: _DimGroupe.largeurMembre,
            child: _Noeud(
              noeud: _NoeudAssoc(fiche: centre),
              rayon: _DimGroupe.rayonCentre,
              onTap: () {},
              accent: null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A group cluster: a shared header (mechanism/“Autre” chip + direction, plus a
/// single “suggested · confidence” line) over a grid of tappable member bubbles
/// (ADR-0013). The single edge/arrow is drawn by [_Peintre].
class _GroupeWidget extends StatelessWidget {
  final _GroupeAssoc groupe;
  final Color accent;
  final void Function(_NoeudAssoc) onTapMembre;

  const _GroupeWidget({
    required this.groupe,
    required this.accent,
    required this.onTapMembre,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Untyped curated pair → neutral "Autre" chip (not a family colour, ADR-0013).
    final estAutre = groupe.mecanisme == null;
    final libelle = groupe.mecanisme ?? l10n.assocMecaAutre;
    final couleurChip = estAutre ? theme.colorScheme.onSurfaceVariant : accent;
    // Second line: "Suggestion · niveau" (derived) or "Hors suggestion"
    // (curated) — both elaborated in the sheet banner on tap (ADR-0013 §6/§7).
    final ligne = groupe.suggere
        ? (groupe.confiance == null
            ? l10n.assocSuggere
            : '${l10n.assocSuggere} · ${groupe.confiance}')
        : l10n.assocHorsSuggestion;

    // The cluster sits inside a rounded shape tinted with the side colour, more
    // muted than the chips so they stay distinct; the single arrow points here
    // (ADR-0013 §5).
    return Container(
      padding: const EdgeInsets.all(_DimGroupe.paddingForme),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.all(RayonsApp.md),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EnteteGroupe(
            libelle: libelle,
            sens: groupe.sens,
            couleur: couleurChip,
            ligne: ligne,
          ),
          const SizedBox(height: EspacementsApp.s1),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final n in groupe.membres)
                SizedBox(
                  width: _DimGroupe.largeurMembre,
                  child: _MembreNoeud(
                    noeud: n,
                    rayon: _DimGroupe.rayonMembre,
                    accent: accent,
                    onTap: () => onTapMembre(n),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shared header of a group: the mechanism/“Autre” chip with a direction glyph
/// (never truncated, ADR-0013 §4), and the once-per-group second line
/// (“Suggestion · …” or “Hors suggestion”).
class _EnteteGroupe extends StatelessWidget {
  final String libelle;
  final SensAssociation? sens;
  final Color couleur;
  final String ligne;

  const _EnteteGroupe({
    required this.libelle,
    required this.sens,
    required this.couleur,
    required this.ligne,
  });

  IconData? get _icone => switch (sens) {
        SensAssociation.donne => Icons.arrow_forward,
        SensAssociation.recoit => Icons.arrow_back,
        SensAssociation.mutuel => Icons.swap_horiz,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EspacementsApp.s2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(RayonsApp.sm),
            border: Border.all(color: couleur.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  libelle,
                  textAlign: TextAlign.center,
                  // No ellipsis: the cluster is wide enough (ADR-0013 §4); wrap
                  // generously rather than truncate.
                  maxLines: 3,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              if (_icone != null) ...[
                const SizedBox(width: 2),
                Icon(_icone, size: 12, color: couleur),
              ],
            ],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          ligne,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: couleur.withValues(alpha: 0.9),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// A single group member: category-coloured disc + name, tappable to open its
/// sheet. The shared label/direction live on the group header (ADR-0013).
class _MembreNoeud extends StatelessWidget {
  final _NoeudAssoc noeud;
  final double rayon;
  final Color accent;
  final VoidCallback onTap;

  const _MembreNoeud({
    required this.noeud,
    required this.rayon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fiche = noeud.fiche;
    final couleur = couleurCategorie(fiche.categorie);
    final disque = couleur.withValues(alpha: noeud.suggere ? 0.45 : 0.9);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: rayon * 2,
            height: rayon * 2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: disque,
              shape: BoxShape.circle,
              border: Border.all(
                color: noeud.suggere
                    ? accent.withValues(alpha: 0.8)
                    : Colors.white,
                width: 1.5,
              ),
            ),
            child: Text(
              fiche.nomLocalise('fr').characters.first.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fiche.nomLocalise('fr'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// A node in the Associations view: category-coloured disc + full name, tappable
/// to open its sheet.
class _Noeud extends StatelessWidget {
  final _NoeudAssoc noeud;
  final double rayon;
  final VoidCallback onTap;

  /// Accent colour of the relationship (good vs to-avoid); `null` for the
  /// centre node.
  final Color? accent;

  const _Noeud({
    required this.noeud,
    required this.rayon,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fiche = noeud.fiche;
    final couleur = couleurCategorie(fiche.categorie);
    final disque = couleur.withValues(alpha: noeud.suggere ? 0.45 : 0.9);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: rayon * 2,
            height: rayon * 2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: disque,
              shape: BoxShape.circle,
              // A dashed-look (thinner, accented) ring marks a derived suggestion.
              border: Border.all(
                color: noeud.suggere && accent != null
                    ? accent!.withValues(alpha: 0.8)
                    : Colors.white,
                width: 1.5,
              ),
            ),
            child: Text(
              fiche.nomLocalise('fr').characters.first.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fiche.nomLocalise('fr'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
          // (ADR-0012) The view shows only the short typed mechanism (when
          // known) and, for a derived node, a "suggested + confidence" tag. The
          // full editorial reason is moved to a banner on the tapped sheet, so
          // nothing is ever truncated here.
          if (noeud.mecanisme != null) ...[
            const SizedBox(height: 3),
            _PuceMecanisme(libelle: noeud.mecanisme!, accent: accent),
          ],
          if (noeud.suggere) ...[
            const SizedBox(height: 2),
            Text(
              noeud.confiance == null
                  ? l10n.assocSuggere
                  : '${l10n.assocSuggere} · ${noeud.confiance}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: (accent ?? theme.colorScheme.primary)
                    .withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small accent-coloured chip naming an association mechanism (ADR-0010).
class _PuceMecanisme extends StatelessWidget {
  final String libelle;
  final Color? accent;

  const _PuceMecanisme({required this.libelle, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = accent ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s1,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(RayonsApp.sm),
        border: Border.all(color: couleur.withValues(alpha: 0.5)),
      ),
      child: Text(
        libelle,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: couleur,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}

/// An edge to draw: the cluster centre [pos], the relation [sens], and the
/// cluster shape half-extents [demi] used to trim the far end so the single
/// arrow stops on the shape's edge (ADR-0012/0013).
typedef _Arete = ({Offset pos, SensAssociation? sens, Size demi});

/// Paints one edge from the centre to each **group** anchor, **with a direction
/// arrow** (ADR-0012/0013): a head at the group end for *donne*, at the centre
/// end for *recoit*, at both for *mutuel*. The far end is trimmed to the group's
/// box so a single arrow points at the cluster rather than through it.
class _Peintre extends CustomPainter {
  final Offset centre;
  final List<_Arete> bons;
  final List<_Arete> eviter;
  final Color couleurBon;
  final Color couleurEviter;
  final double rayonCentre;

  _Peintre({
    required this.centre,
    required this.bons,
    required this.eviter,
    required this.couleurBon,
    required this.couleurEviter,
    required this.rayonCentre,
  });

  @override
  void paint(Canvas canvas, Size size) {
    void trait(List<_Arete> aretes, Color couleur) {
      final p = Paint()
        ..color = couleur.withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (final a in aretes) {
        final vecteur = a.pos - centre;
        final dist = vecteur.distance;
        if (dist < 1) continue;
        final dir = vecteur / dist;
        // Far end: intersection of the ray with the cluster's rectangle, so the
        // arrowhead lands on the shape border, never on a bubble (ADR-0013 §5).
        final tBord = _distanceBord(dir, a.demi);
        final debut = centre + dir * rayonCentre;
        final fin = a.pos - dir * tBord;
        if ((fin - debut).distance < 2) continue;
        canvas.drawLine(debut, fin, p);
        final sens = a.sens ?? SensAssociation.donne;
        if (sens != SensAssociation.recoit) _tete(canvas, debut, fin, p);
        if (sens != SensAssociation.donne) _tete(canvas, fin, debut, p);
      }
    }

    trait(bons, couleurBon);
    trait(eviter, couleurEviter);
  }

  /// Distance from a rectangle's centre to its border along unit vector [dir],
  /// for a rectangle of half-extents [demi].
  static double _distanceBord(Offset dir, Size demi) {
    final tx = dir.dx.abs() < 1e-6 ? double.infinity : demi.width / dir.dx.abs();
    final ty =
        dir.dy.abs() < 1e-6 ? double.infinity : demi.height / dir.dy.abs();
    return math.min(tx, ty);
  }

  /// Draws an arrowhead at [vers], pointing along [depuis] → [vers].
  void _tete(Canvas canvas, Offset depuis, Offset vers, Paint p) {
    const longueur = 8.0;
    const ouverture = 0.5; // radians
    final angle = (vers - depuis).direction;
    canvas.drawLine(
        vers, vers - Offset.fromDirection(angle - ouverture, longueur), p);
    canvas.drawLine(
        vers, vers - Offset.fromDirection(angle + ouverture, longueur), p);
  }

  @override
  bool shouldRepaint(_Peintre old) =>
      old.centre != centre ||
      !identical(old.bons, bons) ||
      !identical(old.eviter, eviter);
}
