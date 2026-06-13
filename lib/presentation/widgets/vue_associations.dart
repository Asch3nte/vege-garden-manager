import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/dimensions_app.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/services/resolveur_compagnonnage.dart';
import '../../l10n/app_localizations.dart';
import 'fiche_plante_detail.dart';
import 'vue_reseau_catalogue.dart' show couleurCategorie;

/// Opens the **Associations** view of [centre]: a dedicated, detailed ego graph
/// of a single species — itself at the centre, its good companions on the left
/// half and the ones to avoid on the right half, **one node per species** (the
/// granular counterpart of the grouped "Réseau" constellation). Reached from the
/// Fiches list (ADR-0008). Companions are resolved over [catalogue] by the
/// shared service, so the split matches the catalogue everywhere.
///
/// Each association reserves room for its **reason**, left empty until the
/// editorial family content exists (ADR-0006 Lot 4) — no invented text.
Future<void> afficherVueAssociations(
  BuildContext context,
  FichePlante centre,
  List<FichePlante> catalogue, {
  void Function(FichePlante)? onAjouter,
}) {
  const resolveur = ResolveurCompagnonnage();
  final comp = resolveur.resoudre(centre, catalogue);
  return showDialog<void>(
    context: context,
    builder: (_) => _VueAssociations(
      centre: centre,
      bons: comp.bons,
      aEviter: comp.aEviter,
      onAjouter: onAjouter,
    ),
  );
}

class _VueAssociations extends StatelessWidget {
  final FichePlante centre;
  final List<FichePlante> bons;
  final List<FichePlante> aEviter;
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
  final List<FichePlante> bons;
  final List<FichePlante> aEviter;
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

    Widget noeud(FichePlante f, Offset p, double rayon) => Positioned(
          left: p.dx - _largeurNoeud / 2,
          top: p.dy - rayon,
          width: _largeurNoeud,
          child: _Noeud(fiche: f, rayon: rayon, onTap: () => onTapNoeud(f)),
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
            noeud(bons[k], posBons[k], _rayonCompagnon),
          for (var k = 0; k < aEviter.length; k++)
            noeud(aEviter[k], posEviter[k], _rayonCompagnon),
          noeud(centre, c, _rayonCentre),
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
  final FichePlante fiche;
  final double rayon;
  final VoidCallback onTap;

  const _Noeud({
    required this.fiche,
    required this.rayon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = couleurCategorie(fiche.categorie);
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
              color: couleur.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
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
          // (ADR-0008 D5) Reason slot — kept empty until the editorial family
          // content / pest référentiel exist (ADR-0006 Lot 4). No invented text.
        ],
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
