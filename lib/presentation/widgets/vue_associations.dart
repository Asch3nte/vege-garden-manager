import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/engine/moteur_derivation_associations.dart';
import '../../application/engine/scoreur_associations.dart';
import '../../application/engine/suggestion_association.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/sens_association.dart';
import '../../domain/services/acces_niveau.dart';
import '../../domain/services/resolveur_compagnonnage.dart';
import '../../domain/value_objects/profil_ponderation_associations.dart';
import '../../l10n/app_localizations.dart';
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
        profil ?? ProfilPonderationAssociations.defaut());
  }

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
  ProfilPonderationAssociations profil,
) {
  const moteur = MoteurDerivationAssociations();
  const scoreur = ScoreurAssociations();
  final parId = {for (final f in catalogue) f.id: f};
  final dejaBons = {for (final n in bons) n.fiche.id};
  final dejaEviter = {for (final n in aEviter) n.fiche.id};

  final meilleurBenef = <String, SuggestionBenefique>{};
  final meilleurConflit = <String, SuggestionConflit>{};
  for (final s in moteur.suggestionsNouvelles(centre, catalogue, familles: familles)) {
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
    this.sens,
    this.bon,
  });
}

class _VueAssociations extends StatefulWidget {
  final FichePlante centre;
  final List<_NoeudAssoc> bons;
  final List<_NoeudAssoc> aEviter;
  final void Function(FichePlante)? onAjouter;

  const _VueAssociations({
    required this.centre,
    required this.bons,
    required this.aEviter,
    required this.onAjouter,
  });

  /// Max derived suggestions shown per side before "voir plus".
  static const int maxDerivesParCote = 5;

  @override
  State<_VueAssociations> createState() => _VueAssociationsState();
}

class _VueAssociationsState extends State<_VueAssociations> {
  bool _tousAffiches = false;

  /// Direction filter (ADR-0012); `null` = all directions.
  SensAssociation? _filtre;

  List<_NoeudAssoc> _filtrer(List<_NoeudAssoc> cote) =>
      _filtre == null ? cote : cote.where((n) => n.sens == _filtre).toList();

  /// The side capped at curated (infinite score) + N derived, unless expanded.
  List<_NoeudAssoc> _affiches(List<_NoeudAssoc> cote) {
    if (_tousAffiches) return cote;
    final nbCurated = cote.where((n) => n.score.isInfinite).length;
    final max = nbCurated + _VueAssociations.maxDerivesParCote;
    return cote.length <= max ? cote : cote.sublist(0, max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final vide = widget.bons.isEmpty && widget.aEviter.isEmpty;
    final bonsF = _filtrer(widget.bons);
    final eviterF = _filtrer(widget.aEviter);
    final bons = _affiches(bonsF);
    final aEviter = _affiches(eviterF);
    final caches =
        (bonsF.length - bons.length) + (eviterF.length - aEviter.length);
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
              : _BarreFiltreSens(
                  filtre: _filtre,
                  onChoisir: (s) => setState(() => _filtre = s),
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
            : InteractiveViewer(
                // Generous pan/zoom so an overflowing constellation is reachable
                // (ADR-0012): zoom far out, pan well beyond the viewport.
                minScale: 0.2,
                maxScale: 4,
                boundaryMargin: const EdgeInsets.all(2000),
                child: LayoutBuilder(
                  builder: (context, c) => _Constellation(
                    taille: Size(c.maxWidth, c.maxHeight),
                    centre: widget.centre,
                    bons: bons,
                    aEviter: aEviter,
                    onTapNoeud: (n) => afficherFichePlanteDetail(
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
                            ),
                    ),
                  ),
                ),
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

/// AppBar filter by association direction (ADR-0012): Tout / Donne / Reçoit /
/// Mutuel.
class _BarreFiltreSens extends StatelessWidget implements PreferredSizeWidget {
  final SensAssociation? filtre;
  final void Function(SensAssociation?) onChoisir;

  const _BarreFiltreSens({required this.filtre, required this.onChoisir});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget puce(String label, SensAssociation? s) => Padding(
          padding: const EdgeInsets.only(right: EspacementsApp.s2),
          child: ChoiceChip(
            label: Text(label),
            selected: filtre == s,
            onSelected: (_) => onChoisir(s),
          ),
        );
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspacementsApp.s4),
        children: [
          puce(l10n.filtreTout, null),
          puce(l10n.sensDonne, SensAssociation.donne),
          puce(l10n.sensRecoit, SensAssociation.recoit),
          puce(l10n.sensMutuel, SensAssociation.mutuel),
        ],
      ),
    );
  }
}

/// The radial ego layout: edges from the centre to each companion, one node per
/// species, and a colour-coded legend per side.
class _Constellation extends StatelessWidget {
  final Size taille;
  final FichePlante centre;
  final List<_NoeudAssoc> bons;
  final List<_NoeudAssoc> aEviter;
  final void Function(_NoeudAssoc) onTapNoeud;

  const _Constellation({
    required this.taille,
    required this.centre,
    required this.bons,
    required this.aEviter,
    required this.onTapNoeud,
  });

  static const double _rayonCentre = 26;
  static const double _rayonCompagnon = 16;
  static const double _largeurNoeud = 120;
  static const double _hauteurNoeud = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // No-overlap ego layout (ADR-0012): centre stays centred; the graph may
    // overflow the viewport — InteractiveViewer (zoom-out / pan) reaches it.
    final res = const LayoutVueAssociations().calculer(
      nbBons: bons.length,
      nbAEviter: aEviter.length,
      tailleNoeud: const Size(_largeurNoeud, _hauteurNoeud),
      zone: taille,
    );
    final c = res.centre;
    final posBons = res.bons;
    final posEviter = res.aEviter;
    final canvasL = taille.width;
    final canvasH = taille.height;

    Widget noeud(_NoeudAssoc n, Offset p, double rayon, Color? accent) =>
        Positioned(
          left: p.dx - _largeurNoeud / 2,
          top: p.dy - rayon,
          width: _largeurNoeud,
          child: _Noeud(
            noeud: n,
            rayon: rayon,
            onTap: () => onTapNoeud(n),
            accent: accent,
          ),
        );

    return SizedBox(
      width: canvasL,
      height: canvasH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(canvasL, canvasH),
            painter: _Peintre(
              centre: c,
              bons: [
                for (var k = 0; k < bons.length; k++)
                  (pos: posBons[k], sens: bons[k].sens),
              ],
              eviter: [
                for (var k = 0; k < aEviter.length; k++)
                  (pos: posEviter[k], sens: aEviter[k].sens),
              ],
              couleurBon: theme.colorScheme.primary,
              couleurEviter: theme.colorScheme.error,
              rayonCentre: _rayonCentre,
              rayonNoeud: _rayonCompagnon,
            ),
          ),
          for (var k = 0; k < bons.length; k++)
            noeud(bons[k], posBons[k], _rayonCompagnon,
                theme.colorScheme.primary),
          for (var k = 0; k < aEviter.length; k++)
            noeud(aEviter[k], posEviter[k], _rayonCompagnon,
                theme.colorScheme.error),
          noeud(_NoeudAssoc(fiche: centre), c, _rayonCentre, null),
          Positioned(
            top: EspacementsApp.s2,
            left: EspacementsApp.s2,
            child: _Entete(
              texte: l10n.reseauNbBons(bons.length),
              couleur: theme.colorScheme.primary,
            ),
          ),
          Positioned(
            top: EspacementsApp.s2,
            right: EspacementsApp.s2,
            child: _Entete(
              texte: l10n.reseauNbEviter(aEviter.length),
              couleur: theme.colorScheme.error,
            ),
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

/// A small colour-coded legend chip ("N bons compagnons" / "N à éviter").
class _Entete extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _Entete({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EspacementsApp.s2,
        vertical: EspacementsApp.s1,
      ),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(RayonsApp.sm),
        border: Border.all(color: couleur.withValues(alpha: 0.6)),
      ),
      child: Text(
        texte,
        style: theme.textTheme.labelSmall?.copyWith(
          color: couleur,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// An edge to draw: the companion [pos] and the relation [sens] (ADR-0012).
typedef _Arete = ({Offset pos, SensAssociation? sens});

/// Paints the edges from the centre to each companion, **with a direction
/// arrow** (ADR-0012): a head at the companion end for *donne*, at the centre
/// end for *recoit*, at both for *mutuel*. Endpoints are trimmed to the bubble
/// radii so heads sit on the bubble border.
class _Peintre extends CustomPainter {
  final Offset centre;
  final List<_Arete> bons;
  final List<_Arete> eviter;
  final Color couleurBon;
  final Color couleurEviter;
  final double rayonCentre;
  final double rayonNoeud;

  _Peintre({
    required this.centre,
    required this.bons,
    required this.eviter,
    required this.couleurBon,
    required this.couleurEviter,
    required this.rayonCentre,
    required this.rayonNoeud,
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
        if (dist < rayonCentre + rayonNoeud + 1) continue;
        final dir = vecteur / dist;
        final debut = centre + dir * rayonCentre;
        final fin = a.pos - dir * rayonNoeud;
        canvas.drawLine(debut, fin, p);
        final sens = a.sens ?? SensAssociation.donne;
        if (sens != SensAssociation.recoit) _tete(canvas, debut, fin, p);
        if (sens != SensAssociation.donne) _tete(canvas, fin, debut, p);
      }
    }

    trait(bons, couleurBon);
    trait(eviter, couleurEviter);
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
