import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/couleurs_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../l10n/app_localizations.dart';
import 'fiche_plante_detail.dart';

/// Decorative accent colour for a plant category (network nodes, mirrors the
/// per-category colour of the `catalogue.jsx` mock-up).
Color couleurCategorie(CategoriePlante c) => switch (c) {
      CategoriePlante.legume => CouleursApp.accentChaudClair,
      CategoriePlante.aromatique => CouleursApp.decoVertMoyen,
      CategoriePlante.fruit => CouleursApp.decoBordeaux,
      CategoriePlante.petitFruit => CouleursApp.decoAubergine,
      CategoriePlante.fleur => CouleursApp.decoAubergineClair,
      CategoriePlante.cereale => CouleursApp.decoTerre,
      CategoriePlante.engraisVert => CouleursApp.decoVertProfond,
    };

/// An association edge between two catalogue nodes (indices into the plant list).
class _Arete {
  final int a;
  final int b;
  final bool bon; // true = good companions, false = to avoid

  const _Arete(this.a, this.b, {required this.bon});

  bool touche(int i) => a == i || b == i;
  int autre(int i) => a == i ? b : a;
}

/// **Réseau** view of the catalogue: a constellation of plants laid out on a
/// Fermat spiral, with edges between companion (and "to avoid") plants.
///
/// Reimplemented from the `catalogue.jsx` `ReseauView`. Tapping a node selects
/// it (highlighting its neighbours); tapping the selected node — or "Voir la
/// fiche" — opens its detail sheet. Associations come from the entity predicates
/// `sAssocieBienAvec` / `entreEnConflitAvec`, so no extra data is needed.
class VueReseauCatalogue extends StatefulWidget {
  final List<FichePlante> fiches;
  final void Function(FichePlante) onAjouter;

  const VueReseauCatalogue({
    required this.fiches,
    required this.onAjouter,
    super.key,
  });

  @override
  State<VueReseauCatalogue> createState() => _VueReseauCatalogueState();
}

class _VueReseauCatalogueState extends State<VueReseauCatalogue> {
  // viewBox of the mock-up SVG; node positions are computed in these coords then
  // scaled to the available width.
  static const double _boiteL = 312;
  static const double _boiteH = 360;
  static const Offset _centre = Offset(156, 172);
  static const double _rayonMax = 116;
  static const double _rayonNoeud = 19;

  late final List<Offset> _positions;
  late final List<_Arete> _aretes;

  int? _selection;
  bool _afficherAEviter = true;

  @override
  void initState() {
    super.initState();
    _positions = _calculerPositions(widget.fiches.length);
    _aretes = _calculerAretes(widget.fiches);
  }

  /// Fermat spiral (golden-angle) positions inside the disk.
  static List<Offset> _calculerPositions(int n) {
    final ga = math.pi * (3 - math.sqrt(5));
    return [
      for (var i = 0; i < n; i++)
        _centre +
            Offset.fromDirection(
              i * ga - math.pi / 2,
              _rayonMax * math.sqrt((i + 0.5) / n),
            ),
    ];
  }

  /// Unique association edges over the whole catalogue (good takes precedence).
  static List<_Arete> _calculerAretes(List<FichePlante> fiches) {
    final aretes = <_Arete>[];
    for (var i = 0; i < fiches.length; i++) {
      for (var j = i + 1; j < fiches.length; j++) {
        final bon = fiches[i].sAssocieBienAvec(fiches[j].id) ||
            fiches[j].sAssocieBienAvec(fiches[i].id);
        final mauvais = fiches[i].entreEnConflitAvec(fiches[j].id) ||
            fiches[j].entreEnConflitAvec(fiches[i].id);
        if (bon) {
          aretes.add(_Arete(i, j, bon: true));
        } else if (mauvais) {
          aretes.add(_Arete(i, j, bon: false));
        }
      }
    }
    return aretes;
  }

  /// Indices linked to [i] (good edges always; bad edges only when shown).
  Set<int> _voisins(int i) => {
        for (final a in _aretes)
          if (a.touche(i) && (a.bon || _afficherAEviter)) a.autre(i),
      };

  void _toucherNoeud(int i) {
    if (_selection == i) {
      _ouvrirFiche(widget.fiches[i]);
    } else {
      setState(() => _selection = i);
    }
  }

  void _ouvrirFiche(FichePlante fiche) {
    afficherFichePlanteDetail(
      context,
      fiche,
      onAjouter: () => widget.onAjouter(fiche),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voisins =
        _selection == null ? const <int>{} : _voisins(_selection!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspacementsApp.s4,
        0,
        EspacementsApp.s4,
        EspacementsApp.s4,
      ),
      child: Column(
        children: [
          // The constellation fills the free space (capped), keeping the panel
          // pinned and visible at the bottom.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final echelle = math.min(
                  constraints.maxWidth / _boiteL,
                  constraints.maxHeight / _boiteH,
                );
                final largeur = _boiteL * echelle;
                final hauteur = _boiteH * echelle;

                return Center(
                  child: SizedBox(
                    width: largeur,
                    height: hauteur,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(largeur, hauteur),
                          painter: _PeintreAretes(
                            positions: _positions,
                            aretes: _aretes,
                            selection: _selection,
                            afficherAEviter: _afficherAEviter,
                            echelle: echelle,
                            couleurBon: theme.colorScheme.primary,
                            couleurMauvais: theme.colorScheme.error,
                          ),
                        ),
                        for (var i = 0; i < widget.fiches.length; i++)
                          Positioned(
                            left: _positions[i].dx * echelle - _rayonNoeud,
                            top: _positions[i].dy * echelle - _rayonNoeud,
                            child: _Noeud(
                              fiche: widget.fiches[i],
                              rayon: _rayonNoeud,
                              etat: _etatNoeud(i, voisins),
                              onTap: () => _toucherNoeud(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _BarreAEviter(
            valeur: _afficherAEviter,
            onChanged: (v) => setState(() => _afficherAEviter = v),
          ),
          const SizedBox(height: EspacementsApp.s3),
          _Panneau(
            fiche: _selection == null ? null : widget.fiches[_selection!],
            nbBons: _selection == null ? 0 : _compter(_selection!, bon: true),
            nbEviter: _selection == null ? 0 : _compter(_selection!, bon: false),
            onVoirFiche: _selection == null
                ? null
                : () => _ouvrirFiche(widget.fiches[_selection!]),
          ),
        ],
      ),
    );
  }

  _EtatNoeud _etatNoeud(int i, Set<int> voisins) {
    if (_selection == null) return _EtatNoeud.normal;
    if (_selection == i) return _EtatNoeud.selectionne;
    return voisins.contains(i) ? _EtatNoeud.lie : _EtatNoeud.attenue;
  }

  int _compter(int i, {required bool bon}) =>
      _aretes.where((a) => a.touche(i) && a.bon == bon).length;
}

/// Visual state of a node given the current selection.
enum _EtatNoeud { normal, selectionne, lie, attenue }

/// A single constellation node (category-coloured disc with the plant initial).
class _Noeud extends StatelessWidget {
  final FichePlante fiche;
  final double rayon;
  final _EtatNoeud etat;
  final VoidCallback onTap;

  const _Noeud({
    required this.fiche,
    required this.rayon,
    required this.etat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = couleurCategorie(fiche.categorie);
    final attenue = etat == _EtatNoeud.attenue;
    final selectionne = etat == _EtatNoeud.selectionne;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: attenue ? 0.30 : 1,
        child: Container(
          width: rayon * 2,
          height: rayon * 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: selectionne ? theme.colorScheme.primary : Colors.white,
              width: selectionne ? 3 : 1.5,
            ),
          ),
          child: Text(
            fiche.nomLocalise('fr').characters.first.toUpperCase(),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// Toggle row controlling whether "to avoid" edges are drawn.
class _BarreAEviter extends StatelessWidget {
  final bool valeur;
  final ValueChanged<bool> onChanged;

  const _BarreAEviter({required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(l10n.reseauAfficherEviter, style: theme.textTheme.bodyMedium),
        ),
        Switch(value: valeur, onChanged: onChanged),
      ],
    );
  }
}

/// Bottom panel: a hint when nothing is selected, otherwise the selected plant's
/// associations and a "see the sheet" action.
class _Panneau extends StatelessWidget {
  final FichePlante? fiche;
  final int nbBons;
  final int nbEviter;
  final VoidCallback? onVoirFiche;

  const _Panneau({
    required this.fiche,
    required this.nbBons,
    required this.nbEviter,
    required this.onVoirFiche,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (fiche == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EspacementsApp.s4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.all(RayonsApp.lg),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Text(
          l10n.reseauIndice,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final couleur = couleurCategorie(fiche!.categorie);
    return Container(
      padding: const EdgeInsets.all(EspacementsApp.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(RayonsApp.lg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: couleur.withValues(alpha: 0.85),
            child: Text(
              fiche!.nomLocalise('fr').characters.first.toUpperCase(),
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fiche!.nomLocalise('fr'), style: theme.textTheme.titleMedium),
                Text(
                  '${l10n.reseauNbBons(nbBons)} · ${l10n.reseauNbEviter(nbEviter)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onVoirFiche,
            child: Text(l10n.reseauVoirFiche),
          ),
        ],
      ),
    );
  }
}

/// Paints the association edges between nodes, dimming those unrelated to the
/// current selection.
class _PeintreAretes extends CustomPainter {
  final List<Offset> positions;
  final List<_Arete> aretes;
  final int? selection;
  final bool afficherAEviter;
  final double echelle;
  final Color couleurBon;
  final Color couleurMauvais;

  _PeintreAretes({
    required this.positions,
    required this.aretes,
    required this.selection,
    required this.afficherAEviter,
    required this.echelle,
    required this.couleurBon,
    required this.couleurMauvais,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final a in aretes) {
      if (!a.bon && !afficherAEviter) continue;
      final chaud = selection == null || a.touche(selection!);
      final base = a.bon ? couleurBon : couleurMauvais;
      final paint = Paint()
        ..color = base.withValues(alpha: chaud ? 0.55 : 0.10)
        ..strokeWidth = (chaud ? 2.0 : 1.0)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(positions[a.a] * echelle, positions[a.b] * echelle, paint);
    }
  }

  @override
  bool shouldRepaint(_PeintreAretes old) =>
      old.selection != selection ||
      old.afficherAEviter != afficherAEviter ||
      old.echelle != echelle;
}
