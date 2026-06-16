import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../../application/engine/moteur_derivation_associations.dart';
import '../../application/engine/suggestion_association.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/services/acces_niveau.dart';
import '../../domain/services/resolveur_compagnonnage.dart';
import '../../l10n/app_localizations.dart';
import 'fiche_plante_detail.dart';
import 'libelles_enums.dart';
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
Future<void> afficherVueAssociations(
  BuildContext context,
  FichePlante centre,
  List<FichePlante> catalogue, {
  void Function(FichePlante)? onAjouter,
  AccesNiveau? acces,
  ResolveurFamille? familles,
}) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).languageCode;
  const resolveur = ResolveurCompagnonnage();
  final comp = resolveur.resoudre(centre, catalogue);

  // Curated companions: typed mechanism + editorial reason (Lot 1).
  final bons = <_NoeudAssoc>[
    for (final c in comp.bonsDetailles)
      _NoeudAssoc(
        fiche: c.fiche,
        mecanisme: c.association.mecanisme == null
            ? null
            : l10n.mecanismeBenefice(c.association.mecanisme!),
        raison: c.association.raison(locale),
      ),
  ];
  final aEviter = <_NoeudAssoc>[
    for (final c in comp.aEviterDetailles)
      _NoeudAssoc(
        fiche: c.fiche,
        mecanisme: c.association.mecanisme == null
            ? null
            : l10n.mecanismeConflit(c.association.mecanisme!),
        raison: c.association.raison(locale),
      ),
  ];

  // Derived suggestions (Lot 3/4), gated by experience level (ADR-0009).
  if (acces?.vueReseau ?? false) {
    _ajouterSuggestions(centre, catalogue, l10n, bons, aEviter, familles);
  }

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

/// Appends the engine's derived suggestions to [bons]/[aEviter], one node per
/// (target, sense) keeping the highest confidence, skipping targets already
/// shown as a curated companion on the same side (curated precedence).
void _ajouterSuggestions(
  FichePlante centre,
  List<FichePlante> catalogue,
  AppLocalizations l10n,
  List<_NoeudAssoc> bons,
  List<_NoeudAssoc> aEviter,
  ResolveurFamille? familles,
) {
  const moteur = MoteurDerivationAssociations();
  final parId = {for (final f in catalogue) f.id: f};
  final dejaBons = {for (final n in bons) n.fiche.id};
  final dejaEviter = {for (final n in aEviter) n.fiche.id};

  final meilleurBenef = <String, SuggestionBenefique>{};
  final meilleurConflit = <String, SuggestionConflit>{};
  for (final s in moteur.suggestionsNouvelles(centre, catalogue, familles: familles)) {
    switch (s) {
      case SuggestionBenefique():
        final e = meilleurBenef[s.cibleId];
        if (e == null || s.confiance.index > e.confiance.index) {
          meilleurBenef[s.cibleId] = s;
        }
      case SuggestionConflit():
        final e = meilleurConflit[s.cibleId];
        if (e == null || s.confiance.index > e.confiance.index) {
          meilleurConflit[s.cibleId] = s;
        }
    }
  }

  for (final s in meilleurBenef.values) {
    final f = parId[s.cibleId];
    if (f == null || dejaBons.contains(f.id)) continue;
    bons.add(_NoeudAssoc(
      fiche: f,
      mecanisme: l10n.mecanismeBenefice(s.mecanisme),
      suggere: true,
      confiance: l10n.confiance(s.confiance),
    ));
  }
  for (final s in meilleurConflit.values) {
    final f = parId[s.cibleId];
    if (f == null || dejaEviter.contains(f.id)) continue;
    aEviter.add(_NoeudAssoc(
      fiche: f,
      mecanisme: l10n.mecanismeConflit(s.mecanisme),
      suggere: true,
      confiance: l10n.confiance(s.confiance),
    ));
  }
}

/// A view-level node: a companion with its already-localised mechanism/reason
/// and, for a derived one, the "suggested" flag and confidence label.
class _NoeudAssoc {
  final FichePlante fiche;
  final String? mecanisme;
  final String? raison;
  final bool suggere;
  final String? confiance;

  const _NoeudAssoc({
    required this.fiche,
    this.mecanisme,
    this.raison,
    this.suggere = false,
    this.confiance,
  });
}

class _VueAssociations extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final vide = bons.isEmpty && aEviter.isEmpty;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(centre.nomLocalise('fr')),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: vide
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
                minScale: 0.5,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(80),
                child: LayoutBuilder(
                  builder: (context, c) => _Constellation(
                    taille: Size(c.maxWidth, c.maxHeight),
                    centre: centre,
                    bons: bons,
                    aEviter: aEviter,
                    onTapNoeud: (f) =>
                        afficherFichePlanteDetail(context, f, onAjouter: onAjouter),
                  ),
                ),
              ),
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
  final void Function(FichePlante) onTapNoeud;

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

  /// [n] points evenly spread on the arc from [a0] to [a1] at radius [r].
  static List<Offset> _arc(int n, Offset c, double r, double a0, double a1) {
    if (n == 0) return const [];
    if (n == 1) return [c + Offset.fromDirection((a0 + a1) / 2, r)];
    return [
      for (var k = 0; k < n; k++)
        c + Offset.fromDirection(a0 + (a1 - a0) * k / (n - 1), r),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final c = Offset(taille.width / 2, taille.height / 2);
    final r = math.min(taille.width, taille.height) * 0.34;
    // Good on the left half, to-avoid on the right half.
    final posBons =
        _arc(bons.length, c, r, math.pi * 100 / 180, math.pi * 260 / 180);
    final posEviter =
        _arc(aEviter.length, c, r, -math.pi * 70 / 180, math.pi * 70 / 180);

    Widget noeud(_NoeudAssoc n, Offset p, double rayon, Color? accent) =>
        Positioned(
          left: p.dx - _largeurNoeud / 2,
          top: p.dy - rayon,
          width: _largeurNoeud,
          child: _Noeud(
            noeud: n,
            rayon: rayon,
            onTap: () => onTapNoeud(n.fiche),
            accent: accent,
          ),
        );

    return SizedBox(
      width: taille.width,
      height: taille.height,
      child: Stack(
        children: [
          CustomPaint(
            size: taille,
            painter: _Peintre(
              centre: c,
              bons: posBons,
              eviter: posEviter,
              couleurBon: theme.colorScheme.primary,
              couleurEviter: theme.colorScheme.error,
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
          // (ADR-0010) The typed mechanism (when known) and, below it, the
          // editorial reason when the catalogue carries one. A derived node adds
          // a "suggested" badge with its confidence. Nothing is invented.
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: (accent ?? theme.colorScheme.primary)
                    .withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (noeud.raison != null) ...[
            const SizedBox(height: 2),
            Text(
              noeud.raison!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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

/// Paints the edges: a coloured line from the centre to each companion.
class _Peintre extends CustomPainter {
  final Offset centre;
  final List<Offset> bons;
  final List<Offset> eviter;
  final Color couleurBon;
  final Color couleurEviter;

  _Peintre({
    required this.centre,
    required this.bons,
    required this.eviter,
    required this.couleurBon,
    required this.couleurEviter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    void trait(List<Offset> pts, Color couleur) {
      final p = Paint()
        ..color = couleur.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (final pt in pts) {
        canvas.drawLine(centre, pt, p);
      }
    }

    trait(bons, couleurBon);
    trait(eviter, couleurEviter);
  }

  @override
  bool shouldRepaint(_Peintre old) =>
      old.centre != centre ||
      !identical(old.bons, bons) ||
      !identical(old.eviter, eviter);
}
