import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/couleurs_app.dart';
import '../../app/theme/dimensions_app.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/services/resolveur_compagnonnage.dart';
import '../../l10n/app_localizations.dart';
import 'fiche_plante_detail.dart';
import 'reseau/halo_famille.dart';
import 'reseau/layout_reseau_familles.dart';

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

/// Maps a **virtual** position (Fermat-spiral coords, never mutated) to a screen
/// position: `screen = virtuel * echelle + offset`. The single source of truth
/// for zoom + x/y pan (ADR-0007) — nodes are laid out at a constant pixel
/// radius, so their labels keep a constant on-screen size whatever the zoom.
class _TransformReseau {
  final double echelle;
  final Offset offset;

  const _TransformReseau(this.echelle, this.offset);

  Offset versEcran(Offset virtuel) => virtuel * echelle + offset;

  static _TransformReseau lerp(
    _TransformReseau a,
    _TransformReseau b,
    double t,
  ) => _TransformReseau(
    a.echelle + (b.echelle - a.echelle) * t,
    Offset.lerp(a.offset, b.offset, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is _TransformReseau &&
      other.echelle == echelle &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(echelle, offset);
}

/// **Réseau** view of the catalogue: a constellation of plants clustered into
/// non-overlapping family bubbles (ADR-0008), with edges between companion (and
/// "to avoid") plants.
///
/// Reimplemented from the `catalogue.jsx` `ReseauView`. Tapping a node selects
/// it (highlighting its neighbours); tapping the selected node — or "Voir la
/// fiche" — opens its detail sheet. Associations come from the entity predicates
/// `sAssocieBienAvec` / `entreEnConflitAvec`, so no extra data is needed.
class VueReseauCatalogue extends StatefulWidget {
  final List<FichePlante> fiches;

  /// Returns the varieties of the species [mereId], listed below the network
  /// when that species is selected (#9).
  final List<FichePlante> Function(String mereId) varietesDe;
  final void Function(FichePlante) onAjouter;

  const VueReseauCatalogue({
    required this.fiches,
    required this.varietesDe,
    required this.onAjouter,
    super.key,
  });

  @override
  State<VueReseauCatalogue> createState() => _VueReseauCatalogueState();
}

class _VueReseauCatalogueState extends State<VueReseauCatalogue>
    with SingleTickerProviderStateMixin {
  // Node disc radius. Unlike ADR-0007 (constant pixel size), the disc now
  // **scales with the zoom** between a floor and a cap [_rayonNoeud]: zoomed out
  // the bubbles shrink (so the whole constellation fits), zoomed in they grow up
  // to their full size (dev request). [_rayonNoeudVirtuel] is the virtual radius
  // mapped through the scale; [_rayonNoeud] stays the on-screen maximum (and the
  // value the label-spreading maths #8b reserves against).
  static const double _rayonNoeud = 19;
  static const double _rayonNoeudVirtuel = 13;
  static const double _rayonNoeudMin = 3;

  // Max screen distance (px) from a node centre at which a tap that missed every
  // disc still selects it (ADR-0008 Voronoï hit-testing): the shrunk discs
  // (dezoom) keep a generous hitbox — bounded and never overlapping by
  // construction (nearest-point assignment) — without changing the visual.
  static const double _hitboxMax = 28;

  /// On-screen node radius at transform [t]: virtual radius × scale, clamped
  /// between the floor and the cap.
  double _rayonEcran(_TransformReseau t) =>
      (_rayonNoeudVirtuel * t.echelle).clamp(_rayonNoeudMin, _rayonNoeud);

  // Zoom bounds (absolute), the +/- button step, and the cap applied when
  // fitting a small selection so a lone node doesn't zoom in absurdly (#8a).
  // The floor is low enough that the whole family-bubble constellation fits at
  // the baseline (ADR-0008).
  static const double _echelleMin = 0.15;
  static const double _echelleMax = 4.0;
  static const double _echelleAjustMax = 2.0;
  static const double _facteurZoom = 1.3;

  // Breathing room added around each label footprint during de-overlap (#8b),
  // so neighbours keep a visible gap rather than just touching.
  static const double _ecartLabel = 6.0;

  // Idle delay after the last pan/zoom before the de-overlap is recomputed once
  // (#8b): cheap, and re-spreads labels that a manual zoom-out brought together.
  static const Duration _delaiReajustement = Duration(seconds: 1);

  // BOX 2 (the draggable fiches sheet) sizes, as a fraction of the view height:
  // resting (BOX 1 large) and max (capped at half the screen, so BOX 1 never
  // shrinks below half — past the max the sheet scrolls internally).
  static const double _feuilleMin = 0.32;
  static const double _feuilleMax = 0.5;

  late final List<Offset> _positions;
  // Family circles (centre + radius), packed without overlap (ADR-0008) — drive
  // the blobby family halos and the baseline framing.
  late final List<FoyerFamille> _foyers;
  // Union of the family circles, in virtual coords — the baseline fits this.
  late final Rect _bbox;
  late final List<_Arete> _aretes;

  int? _selection;
  bool _afficherAEviter = true;
  // Collapsible display-controls menu (zoom + toggles), like the search button.
  bool _menuControlesOuvert = false;
  // Toggles from that menu: draw the edges, and the family halo labels.
  bool _afficherLiens = true;
  bool _afficherNomsFamille = true;

  // Current view transform; `null` means the baseline (fit + centered), which
  // also serves as the "recenter" target. Recomputed from the viewport so the
  // constellation reacts to resizes until the user interacts.
  _TransformReseau? _transform;
  Size _viewport = Size.zero;
  // Transform and local focal point captured at the start of a pan/pinch.
  _TransformReseau? _depart;
  Offset _focalDepart = Offset.zero;

  // Per-node display displacement, in **virtual** units, applied only to named
  // nodes while a selection is active (#8b anti-overlap). Never mutates the
  // canonical [_positions]; cleared/recomputed as the selection or fit changes.
  Map<int, Offset> _decalages = const {};

  // Drives the animated recenter / fit-to-selection (#8a) and the de-overlap
  // displacement (#8b) — both interpolated on the same controller.
  late final AnimationController _ctrl;
  _TransformReseau _animDebut = const _TransformReseau(1, Offset.zero);
  _TransformReseau _animFin = const _TransformReseau(1, Offset.zero);
  Map<int, Offset> _decalagesDebut = const {};
  Map<int, Offset> _decalagesFin = const {};

  // Debounces the post-movement de-overlap recompute (#8b).
  Timer? _reajustement;

  // Debounces re-fitting the selection when BOX 1 is resized (sheet drag), so
  // the framing/labels follow the new box size instead of the old one.
  Timer? _recadrageTaille;

  // Drives BOX 2 (the fiches sheet); its size shrinks BOX 1 (the network) and
  // toggles the compact form (#10).
  final DraggableScrollableController _feuille =
      DraggableScrollableController();
  double _tailleFeuille = _feuilleMin;

  // Free-text search by name (Lot 5): selects + frames the matching species.
  // Collapsed to a magnifier button until opened.
  final TextEditingController _ctrlRecherche = TextEditingController();
  bool _rechercheOuverte = false;
  bool _rechercheSansResultat = false;

  @override
  void initState() {
    super.initState();
    final resultat = const LayoutReseauFamilles().calculer([
      for (final f in widget.fiches) NoeudLayout(f.id, f.familleBotanique),
    ]);
    _positions = resultat.positions;
    _foyers = resultat.foyers;
    _bbox = _unionFoyers(resultat.foyers);
    _aretes = _calculerAretes(widget.fiches);
    _feuille.addListener(_surFeuille);
    _ctrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 280),
        )..addListener(() {
          final v = Curves.easeInOut.transform(_ctrl.value);
          setState(() {
            _transform = _TransformReseau.lerp(_animDebut, _animFin, v);
            _decalages = _lerpDecalages(_decalagesDebut, _decalagesFin, v);
          });
        });
  }

  @override
  void dispose() {
    _reajustement?.cancel();
    _recadrageTaille?.cancel();
    _feuille.removeListener(_surFeuille);
    _feuille.dispose();
    _ctrlRecherche.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// Tracks BOX 2's size so BOX 1 (the network) resizes to the space above it.
  void _surFeuille() {
    if (!mounted || !_feuille.isAttached) return;
    setState(() => _tailleFeuille = _feuille.size);
  }

  /// After BOX 1 settles at a new size (debounced, each resize re-arms it),
  /// re-fit the selection so its framing and labels match the new box. Without
  /// a selection the baseline already re-fits from the live viewport.
  void _planifierRecadrageTaille() {
    if (_selection == null) return;
    _recadrageTaille?.cancel();
    _recadrageTaille = Timer(const Duration(milliseconds: 120), () {
      if (mounted && _selection != null) _cadrerSelection();
    });
  }

  /// (Re)arms the idle timer that recomputes the de-overlap once the user stops
  /// panning/zooming (#8b) — each movement re-arms it, so it fires only after
  /// the last one. No-op without an active selection.
  void _planifierReajustement() {
    if (_selection == null) return;
    _reajustement?.cancel();
    _reajustement = Timer(_delaiReajustement, () {
      if (!mounted || _selection == null) return;
      final t = _transformActuel(_viewport);
      // Keep the view where the user left it; only re-spread the labels.
      _recadrer(t);
    });
  }

  /// Animates the view transform and the per-node displacements from their
  /// current values to ([cible], [decalages]).
  void _animerVers(_TransformReseau cible, Map<int, Offset> decalages) {
    _animDebut = _transformActuel(_viewport);
    _animFin = cible;
    _decalagesDebut = _decalages;
    _decalagesFin = decalages;
    _ctrl.forward(from: 0);
  }

  /// Interpolates two displacement maps, treating a missing key as no offset, so
  /// nodes leaving the named set ease back to their canonical position.
  static Map<int, Offset> _lerpDecalages(
    Map<int, Offset> a,
    Map<int, Offset> b,
    double t,
  ) {
    final cles = {...a.keys, ...b.keys};
    return {
      for (final k in cles)
        k: Offset.lerp(a[k] ?? Offset.zero, b[k] ?? Offset.zero, t)!,
    };
  }

  /// Display position of node [i]: its canonical spot plus any active
  /// de-overlap displacement (#8b).
  Offset _posAffichee(int i) => _positions[i] + (_decalages[i] ?? Offset.zero);

  /// The selected node and its links — the nodes shown with a full-name label.
  Set<int> _nommes() =>
      _selection == null ? const {} : {_selection!, ..._voisins(_selection!)};

  /// Frames the selection + links and spreads their labels (#8a/#8b), animating
  /// into view. Fits with label room, spreads, then re-fits to the spread result
  /// (and re-spreads at that scale) so nothing is clipped.
  void _cadrerSelection() {
    _reajustement?.cancel(); // this immediate pass supersedes any pending one
    final named = _nommes();
    if (named.isEmpty) return;
    final style = _styleEtiquette(context);
    final (padX, padY) = _reserveLabels(named, style);
    const marge = 12.0;
    final dispoL = _viewport.width - 2 * marge;
    final dispoH = _viewport.height - 2 * marge;
    // Pick an initial scale by fitting the centres, then de-overlap. If the
    // spread footprints overflow, shrink the scale and re-spread: footprints
    // shrink as the scale does (the centres draw closer while the fixed-size
    // labels set a constant floor), so this converges to a scale that fits —
    // with the final displacements honoured at the final scale (no overlap).
    var t = _ajusterSur(named, const {}, _viewport, padX, padY);
    var d = _resoudreChevauchement(named, t, style);
    for (var k = 0; k < 8; k++) {
      final bbox = _empreinteBbox(named, d, t, style);
      if (bbox.width <= dispoL && bbox.height <= dispoH) break;
      final c = math.min(dispoL / bbox.width, dispoH / bbox.height);
      final echelle = (t.echelle * c).clamp(_echelleMin, _echelleAjustMax);
      if (echelle >= t.echelle) break; // can't shrink further (hit the floor)
      t = _TransformReseau(echelle, t.offset);
      d = _resoudreChevauchement(named, t, style);
    }
    // Translate (no rescale) so the spread result is centred — and so the gaps
    // the spread opened are preserved.
    final bbox = _empreinteBbox(named, d, t, style);
    final centreVue = Offset(_viewport.width / 2, _viewport.height / 2);
    final t2 = _TransformReseau(
      t.echelle,
      t.offset + (centreVue - bbox.center),
    );
    _animerVers(t2, d);
  }

  /// Keeps the view at [cible] and only (re)spreads the named labels (#8b) — for
  /// recenter, the "à éviter" toggle and the post-movement debounce.
  void _recadrer(_TransformReseau cible) {
    _reajustement?.cancel();
    final style = _styleEtiquette(context);
    _animerVers(cible, _resoudreChevauchement(_nommes(), cible, style));
  }

  TextStyle _styleEtiquette(BuildContext context) =>
      Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600) ??
      const TextStyle(fontWeight: FontWeight.w600);

  /// Bounding box of all family circles (centre ± radius), in virtual coords.
  static Rect _unionFoyers(List<FoyerFamille> foyers) {
    if (foyers.isEmpty) return Rect.zero;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final f in foyers) {
      minX = math.min(minX, f.centre.dx - f.rayon);
      minY = math.min(minY, f.centre.dy - f.rayon);
      maxX = math.max(maxX, f.centre.dx + f.rayon);
      maxY = math.max(maxY, f.centre.dy + f.rayon);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Unique association edges over the whole catalogue, using the shared
  /// resolver so the polarity (and the resulting counts) match the detail sheet
  /// exactly — bidirectional, good taking precedence (ADR-0008).
  static List<_Arete> _calculerAretes(List<FichePlante> fiches) {
    const resolveur = ResolveurCompagnonnage();
    final aretes = <_Arete>[];
    for (var i = 0; i < fiches.length; i++) {
      for (var j = i + 1; j < fiches.length; j++) {
        switch (resolveur.relationEntre(fiches[i], fiches[j])) {
          case TypeCompagnonnage.bon:
            aretes.add(_Arete(i, j, bon: true));
          case TypeCompagnonnage.aEviter:
            aretes.add(_Arete(i, j, bon: false));
          case TypeCompagnonnage.aucune:
            break;
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
      // Frame the selection and its neighbours (#8a) and spread their labels so
      // none overlap (#8b), animating into view.
      _cadrerSelection();
    }
  }

  /// Voronoï-style canvas hit-testing (ADR-0008): a tap that missed every disc
  /// selects the **nearest** node when within [_hitboxMax] screen pixels, so the
  /// shrunk discs (dezoom) stay easy to hit. Precise taps landing on a disc (or
  /// on a grouped name, control, search…) are handled by those widgets' own
  /// recognizers, which win the gesture arena — this only catches taps in the
  /// empty space around a node. The nearest-point assignment makes the hitboxes
  /// non-overlapping and self-deforming by construction.
  void _surTapCanvas(TapUpDetails d) {
    if (widget.fiches.isEmpty) return;
    final t = _transformActuel(_viewport);
    int? plusProche;
    var meilleure = double.infinity;
    for (var i = 0; i < widget.fiches.length; i++) {
      // Use the same on-screen centre the canvas renders: displaced in the
      // global view (#8b), canonical in focus (grouped nodes ignore #8b).
      final centre = t.versEcran(
        _selection == null ? _posAffichee(i) : _positions[i],
      );
      final dist = (centre - d.localPosition).distance;
      if (dist < meilleure) {
        meilleure = dist;
        plusProche = i;
      }
    }
    if (plusProche != null && meilleure <= _hitboxMax) {
      _toucherNoeud(plusProche);
    }
  }

  /// Lowercases and strips diacritics (keeps spaces) for accent-insensitive
  /// name search (Lot 5, ADR-0008).
  static String _normaliser(String s) {
    const accents = 'àâäáãåçèêëéìîïíòôöóõùûüú';
    const sans = 'aaaaaaceeeeiiiiooooouuuu';
    final buffer = StringBuffer();
    for (final rune in s.toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      final i = accents.indexOf(c);
      buffer.write(i >= 0 ? sans[i] : c);
    }
    return buffer.toString();
  }

  /// Finds the first species whose name contains [requete] and selects + frames
  /// it (like a tap); flags "no result" otherwise (Lot 5).
  void _rechercher(String requete) {
    final terme = _normaliser(requete.trim());
    if (terme.isEmpty) {
      setState(() => _rechercheSansResultat = false);
      return;
    }
    final idx = widget.fiches.indexWhere(
      (f) => _normaliser(f.nomLocalise('fr')).contains(terme),
    );
    if (idx < 0) {
      setState(() => _rechercheSansResultat = true);
      return;
    }
    setState(() {
      _rechercheSansResultat = false;
      _selection = idx;
    });
    _cadrerSelection();
    FocusScope.of(context).unfocus();
  }

  /// Closes the search: clears the field, collapses it back to the magnifier,
  /// and **drops the focus** (deselects + recenters) to return to the global
  /// view (tweak #2/#5).
  void _fermerRecherche() {
    _ctrlRecherche.clear();
    setState(() {
      _rechercheOuverte = false;
      _rechercheSansResultat = false;
      _selection = null;
    });
    _recentrer();
    FocusScope.of(context).unfocus();
  }

  /// In the **global** (unselected) view, the set of nodes whose constant-size
  /// name label fits at transform [t] without overlapping any node disc or an
  /// already-placed label (tweak #6) — greedy, deterministic by index order.
  Set<int> _labelsQuiTiennent(_TransformReseau t, TextStyle style) {
    final rayon = _rayonEcran(t);
    final discs = [
      for (var i = 0; i < widget.fiches.length; i++)
        Rect.fromCircle(center: t.versEcran(_positions[i]), radius: rayon),
    ];
    final acceptes = <int>{};
    final rects = <Rect>[];
    for (var i = 0; i < widget.fiches.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: widget.fiches[i].nomLocalise('fr'), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final centre = t.versEcran(_positions[i]);
      final rect = Rect.fromLTWH(
        centre.dx - (tp.width + 14) / 2,
        centre.dy + rayon + 2,
        tp.width + 14,
        tp.height + 6,
      );
      var heurte = false;
      for (final d in discs) {
        if (rect.overlaps(d)) {
          heurte = true;
          break;
        }
      }
      if (!heurte) {
        for (final r in rects) {
          if (rect.overlaps(r)) {
            heurte = true;
            break;
          }
        }
      }
      if (!heurte) {
        acceptes.add(i);
        rects.add(rect);
      }
    }
    return acceptes;
  }

  /// Fit-to-view transform framing the **displaced** virtual positions of
  /// [indices] (canonical + [decalages]) inside [vue]. Reserves [padX]/[padY]
  /// screen pixels on each side for the constant-size labels so they are never
  /// clipped at the edges (#8a/#8b).
  _TransformReseau _ajusterSur(
    Set<int> indices,
    Map<int, Offset> decalages,
    Size vue,
    double padX,
    double padY,
  ) {
    if (indices.isEmpty || vue.isEmpty) return _transformActuel(vue);
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final i in indices) {
      final p = _positions[i] + (decalages[i] ?? Offset.zero);
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    const marge = 16.0; // small base margin; label padding does the rest
    final dispoL = math.max(vue.width - 2 * marge - 2 * padX, 1.0);
    final dispoH = math.max(vue.height - 2 * marge - 2 * padY, 1.0);
    final echelle = math
        .min(
          dispoL / math.max(maxX - minX, 1.0),
          dispoH / math.max(maxY - minY, 1.0),
        )
        .clamp(_echelleMin, _echelleAjustMax);
    final centreV = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    return _TransformReseau(
      echelle,
      Offset(vue.width / 2, vue.height / 2) - centreV * echelle,
    );
  }

  /// Screen bounding box of the node + label footprints of [noeuds] at transform
  /// [t] with displacements [decalages] — used to centre the spread result in
  /// the viewport without rescaling it (#8b).
  Rect _empreinteBbox(
    Set<int> noeuds,
    Map<int, Offset> decalages,
    _TransformReseau t,
    TextStyle style,
  ) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final i in noeuds) {
      final tp = TextPainter(
        text: TextSpan(text: widget.fiches[i].nomLocalise('fr'), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final demiL = math.max(tp.width + 14, _rayonNoeud * 2) / 2;
      final a = t.versEcran(_positions[i] + (decalages[i] ?? Offset.zero));
      minX = math.min(minX, a.dx - demiL);
      maxX = math.max(maxX, a.dx + demiL);
      minY = math.min(minY, a.dy - _rayonNoeud);
      maxY = math.max(maxY, a.dy + _rayonNoeud + 2 + (tp.height + 6));
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Screen-space room the labels of [noeuds] need on each side of a node
  /// centre (half label width; disc + gap + label height below), used to keep
  /// the fit from clipping them (#8b).
  (double, double) _reserveLabels(Set<int> noeuds, TextStyle style) {
    var padX = _rayonNoeud, padY = _rayonNoeud;
    for (final i in noeuds) {
      final tp = TextPainter(
        text: TextSpan(text: widget.fiches[i].nomLocalise('fr'), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final demiL = math.max(tp.width + 14, _rayonNoeud * 2) / 2 + _ecartLabel;
      final bas = _rayonNoeud + 2 + (tp.height + 6) + _ecartLabel;
      padX = math.max(padX, demiL);
      padY = math.max(padY, bas);
    }
    return (padX, padY);
  }

  /// Computes per-node **virtual** displacements that spread the labels of
  /// [noeuds] so none overlap at transform [t] (#8b).
  ///
  /// Each named node owns a screen-space footprint (its disc plus the full-name
  /// label below it, sized via a [TextPainter] with [style]). An iterative
  /// AABB separation pushes overlapping footprints apart along their axis of
  /// least penetration; the net screen movement is converted back to virtual
  /// units (÷ scale) so it composes with the transform and rides along on zoom.
  Map<int, Offset> _resoudreChevauchement(
    Set<int> noeuds,
    _TransformReseau t,
    TextStyle style,
  ) {
    if (noeuds.length < 2) return const {};
    final liste = noeuds.toList();
    final centres = <int, Offset>{}; // footprint centre (screen)
    final origines = <int, Offset>{}; // footprint centre before separation
    final demi = <int, Size>{}; // half-extents (screen)
    for (final i in liste) {
      final tp = TextPainter(
        text: TextSpan(text: widget.fiches[i].nomLocalise('fr'), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelL = tp.width + 14; // 6px padding ×2 + 1px border ×2
      final labelH = tp.height + 6;
      final largeur = math.max(labelL, _rayonNoeud * 2);
      final hauteur = _rayonNoeud * 2 + 2 + labelH; // disc + gap + label
      final ancre = t.versEcran(_positions[i]);
      // Footprint spans the disc top down to the label bottom; its centre sits
      // (2 + labelH)/2 below the node centre.
      final centre = Offset(ancre.dx, ancre.dy + (2 + labelH) / 2);
      centres[i] = centre;
      origines[i] = centre;
      // Inflate the footprint by the gap so neighbours separate with breathing
      // room instead of just touching.
      demi[i] = Size(largeur / 2 + _ecartLabel, hauteur / 2 + _ecartLabel);
    }
    const iters = 60;
    for (var k = 0; k < iters; k++) {
      var bouge = false;
      for (var a = 0; a < liste.length; a++) {
        for (var b = a + 1; b < liste.length; b++) {
          final ia = liste[a], ib = liste[b];
          final ca = centres[ia]!, cb = centres[ib]!;
          final da = demi[ia]!, db = demi[ib]!;
          final dx = cb.dx - ca.dx, dy = cb.dy - ca.dy;
          final ox = (da.width + db.width) - dx.abs();
          final oy = (da.height + db.height) - dy.abs();
          if (ox > 0 && oy > 0) {
            bouge = true;
            if (ox < oy) {
              final s = (dx >= 0 ? 1.0 : -1.0) * ox / 2;
              centres[ia] = ca.translate(-s, 0);
              centres[ib] = cb.translate(s, 0);
            } else {
              final s = (dy >= 0 ? 1.0 : -1.0) * oy / 2;
              centres[ia] = ca.translate(0, -s);
              centres[ib] = cb.translate(0, s);
            }
          }
        }
      }
      if (!bouge) break;
    }
    final res = <int, Offset>{};
    for (final i in liste) {
      final deplacement = (centres[i]! - origines[i]!) / t.echelle;
      if (deplacement.distance > 0.01) res[i] = deplacement;
    }
    return res;
  }

  void _ouvrirFiche(FichePlante fiche) {
    afficherFichePlanteDetail(context, fiche, onAjouter: widget.onAjouter);
  }

  /// The active transform, falling back to the baseline (fit + centered) sized
  /// to [vue].
  _TransformReseau _transformActuel(Size vue) => _transform ?? _baseline(vue);

  /// Baseline transform: the whole constellation (every family circle) scaled to
  /// fit [vue] and centered — the pre-zoom layout and the "recenter" target.
  _TransformReseau _baseline(Size vue) {
    if (vue.isEmpty || _bbox.isEmpty) {
      return const _TransformReseau(1, Offset.zero);
    }
    const marge = 10.0;
    final echelle = math
        .min(
          (vue.width - 2 * marge) / _bbox.width,
          (vue.height - 2 * marge) / _bbox.height,
        )
        .clamp(_echelleMin, _echelleMax);
    return _TransformReseau(
      echelle,
      Offset(vue.width / 2, vue.height / 2) - _bbox.center * echelle,
    );
  }

  void _debutGeste(ScaleStartDetails d) {
    _ctrl.stop(); // a manual gesture takes over from any running animation
    _depart = _transformActuel(_viewport);
    _focalDepart = d.localFocalPoint;
  }

  /// Combined pan + pinch: keeps the content point under the initial focal point
  /// anchored to the current focal point, so panning and zooming feel natural.
  void _majGeste(ScaleUpdateDetails d) {
    final depart = _depart;
    if (depart == null) return;
    final echelle = (depart.echelle * d.scale).clamp(_echelleMin, _echelleMax);
    final ancrage = (_focalDepart - depart.offset) / depart.echelle;
    setState(
      () => _transform = _TransformReseau(
        echelle,
        d.localFocalPoint - ancrage * echelle,
      ),
    );
    _planifierReajustement();
  }

  /// Zooms by [facteur] around the viewport centre (for the +/- buttons).
  void _zoomer(double facteur) {
    final t = _transformActuel(_viewport);
    final centre = Offset(_viewport.width / 2, _viewport.height / 2);
    final echelle = (t.echelle * facteur).clamp(_echelleMin, _echelleMax);
    final ancrage = (centre - t.offset) / t.echelle;
    setState(
      () => _transform = _TransformReseau(echelle, centre - ancrage * echelle),
    );
    _planifierReajustement();
  }

  /// Resets zoom/pan back to the baseline (fit + centered), animated. Keeps an
  /// active selection's labels spread (#8b) at the baseline scale.
  void _recentrer() => _recadrer(_baseline(_viewport));

  @override
  Widget build(BuildContext context) {
    final selection = _selection;
    final mere = selection == null ? null : widget.fiches[selection];
    final varietes = (mere != null && mere.estMere)
        ? widget.varietesDe(mere.id)
        : const <FichePlante>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        // BOX 1 (network) fills the space *above* BOX 2 (the sheet): it shrinks
        // as the sheet grows, never overlapped. Both stay independent — pan/zoom
        // lives on BOX 1, scroll/tap on BOX 2.
        final hauteurBox1 = (constraints.maxHeight * (1 - _tailleFeuille))
            .clamp(0.0, constraints.maxHeight);
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: hauteurBox1,
              child: _construireCanvas(context),
            ),
            DraggableScrollableSheet(
              controller: _feuille,
              initialChildSize: _feuilleMin,
              minChildSize: _feuilleMin,
              maxChildSize: _feuilleMax,
              builder: (context, defilement) => _construireFeuille(
                context,
                defilement,
                mere,
                selection,
                varietes,
              ),
            ),
          ],
        );
      },
    );
  }

  /// BOX 2: the draggable fiches sheet — toggle + selected-species panel + its
  /// varieties (#9). Swiping it up shrinks BOX 1 (#10); it scrolls internally
  /// once fully expanded.
  Widget _construireFeuille(
    BuildContext context,
    ScrollController defilement,
    FichePlante? mere,
    int? selection,
    List<FichePlante> varietes,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: RayonsApp.lg),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: defilement,
        padding: const EdgeInsets.fromLTRB(
          EspacementsApp.s4,
          EspacementsApp.s2,
          EspacementsApp.s4,
          EspacementsApp.s4,
        ),
        children: [
          // Grip handle, hinting the sheet can be dragged.
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: EspacementsApp.s2),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          _BarreAEviter(
            valeur: _afficherAEviter,
            onChanged: (v) {
              setState(() => _afficherAEviter = v);
              // The named set (links) changed → re-spread labels at the current
              // view so none overlap (#8b).
              if (_selection != null) {
                _recadrer(_transformActuel(_viewport));
              }
            },
          ),
          const SizedBox(height: EspacementsApp.s3),
          _Panneau(
            fiche: mere,
            nbBons: selection == null ? 0 : _compter(selection, bon: true),
            nbEviter: selection == null ? 0 : _compter(selection, bon: false),
            onVoirFiche: mere == null ? null : () => _ouvrirFiche(mere),
          ),
          if (varietes.isNotEmpty) const SizedBox(height: EspacementsApp.s3),
          for (final v in varietes)
            _LigneVarieteReseau(fiche: v, onAjouter: widget.onAjouter),
        ],
      ),
    );
  }

  /// Builds the interactive constellation canvas (#7/#8). Behaves identically
  /// whether BOX 1 is reduced or not: bubbles + full names + de-overlap.
  Widget _construireCanvas(BuildContext context) {
    final theme = Theme.of(context);
    final voisins = _selection == null ? const <int>{} : _voisins(_selection!);
    // Selected node + its links — full-name labels and paint order (#8a).
    final surlignes = _selection == null
        ? const <int>{}
        : {_selection!, ...voisins};
    // Paint dimmed (attenuated) nodes first and highlighted ones on top, so a
    // displaced node under an attenuated disc keeps its full opacity (#8b).
    final ordreNoeuds = [
      for (var i = 0; i < widget.fiches.length; i++)
        if (!surlignes.contains(i)) i,
      for (var i = 0; i < widget.fiches.length; i++)
        if (surlignes.contains(i)) i,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final nouveauViewport = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if (nouveauViewport != _viewport) {
          _viewport = nouveauViewport;
          // BOX 1 changed size → re-fit the selection for the new box.
          _planifierRecadrageTaille();
        }
        // Live transform/displacements so pan/zoom/tap keep updating, and the
        // framing/labels stay identical whether BOX 1 is reduced or not.
        final t = _transformActuel(_viewport);
        final decalages = _decalages;
        Offset posAffichee(int i) => _posAffichee(i);

        // Node disc radius at this zoom; attenuated nodes (in focus) halve it
        // and fade more (tweak #3). Bubbles scale with zoom (dev request).
        final rBase = _rayonEcran(t);
        double rayonDe(int i) =>
            (_selection != null &&
                    _etatNoeud(i, voisins) == _EtatNoeud.attenue)
                ? rBase / 2
                : rBase;
        // Which nodes show a full-name label: in focus, the focus set (#8a); in
        // the global view, those whose label fits without overlap at this zoom
        // (tweak #6).
        final style = _styleEtiquette(context);
        final nommes = _selection == null
            ? _labelsQuiTiennent(t, style)
            : const <int>{};

        // Node + label layer. Global view: plain discs + the labels that fit
        // (#6). Focus: same-family links collapse into one grouped node — family
        // name above, species listed below, each tappable (dev request).
        final List<Widget> coucheNoeuds;
        if (_selection == null) {
          coucheNoeuds = [
            for (final i in ordreNoeuds)
              Positioned(
                left: t.versEcran(posAffichee(i)).dx - rayonDe(i),
                top: t.versEcran(posAffichee(i)).dy - rayonDe(i),
                child: _Noeud(
                  fiche: widget.fiches[i],
                  rayon: rayonDe(i),
                  etat: _etatNoeud(i, voisins),
                  onTap: () => _toucherNoeud(i),
                ),
              ),
            for (final i in nommes)
              Positioned(
                left: t.versEcran(posAffichee(i)).dx,
                top: t.versEcran(posAffichee(i)).dy + rBase + 2,
                child: IgnorePointer(
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: _EtiquetteNoeud(
                      nom: widget.fiches[i].nomLocalise('fr'),
                      couleur: couleurCategorie(widget.fiches[i].categorie),
                    ),
                  ),
                ),
              ),
          ];
        } else {
          coucheNoeuds = _coucheFocus(t, rBase, voisins);
        }

        // The whole canvas pans/zooms; the gesture arena lets node taps and the
        // controls win their own taps, while drags pan/zoom.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _debutGeste,
          onScaleUpdate: _majGeste,
          // A stationary tap on the empty canvas resolves to this recognizer
          // (a drag/pinch goes to the scale one); it selects the nearest node
          // within [_hitboxMax] (Voronoï hit-testing, #3).
          onTapUp: _surTapCanvas,
          child: ClipRect(
            child: Stack(
              children: [
                // Family halos sit under the edges and nodes (ADR-0008).
                CustomPaint(
                  size: _viewport,
                  painter: _PeintreFoyers(
                    foyers: _foyers,
                    transform: t,
                    // Global view: every family labelled (unless the toggle is
                    // off). In focus, halo labels are suppressed — the grouped
                    // family nodes carry the family name instead (dev request).
                    famillesAvecLabel: (_afficherNomsFamille && _selection == null)
                        ? null
                        : const <String>{},
                    couleurFond: theme.colorScheme.surface,
                  ),
                ),
                if (_afficherLiens)
                  CustomPaint(
                    size: _viewport,
                    painter: _PeintreAretes(
                      positions: _positions,
                      // In focus the grouped nodes sit at canonical positions, so
                      // the edges follow them (no #8b displacement applied).
                      decalages:
                          _selection == null ? decalages : const <int, Offset>{},
                      aretes: _aretes,
                      selection: _selection,
                      afficherAEviter: _afficherAEviter,
                      transform: t,
                      couleurBon: theme.colorScheme.primary,
                      couleurMauvais: theme.colorScheme.error,
                    ),
                  ),
                ...coucheNoeuds,
                Positioned(
                  top: EspacementsApp.s2,
                  left: EspacementsApp.s2,
                  child: _BarreRecherche(
                    controleur: _ctrlRecherche,
                    ouverte: _rechercheOuverte,
                    sansResultat: _rechercheSansResultat,
                    onOuvrir: () => setState(() => _rechercheOuverte = true),
                    onSoumettre: _rechercher,
                    onEffacer: _fermerRecherche,
                    onReplier: () =>
                        setState(() => _rechercheOuverte = false),
                  ),
                ),
                Positioned(
                  top: EspacementsApp.s2,
                  right: EspacementsApp.s2,
                  child: _ControlesZoom(
                    ouvert: _menuControlesOuvert,
                    onOuvrir: () =>
                        setState(() => _menuControlesOuvert = true),
                    onFermer: () =>
                        setState(() => _menuControlesOuvert = false),
                    onZoomAvant: () => _zoomer(_facteurZoom),
                    onZoomArriere: () => _zoomer(1 / _facteurZoom),
                    onRecentrer: _recentrer,
                    afficherLiens: _afficherLiens,
                    onToggleLiens: () =>
                        setState(() => _afficherLiens = !_afficherLiens),
                    afficherNoms: _afficherNomsFamille,
                    onToggleNoms: () => setState(
                      () => _afficherNomsFamille = !_afficherNomsFamille,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _EtatNoeud _etatNoeud(int i, Set<int> voisins) {
    if (_selection == null) return _EtatNoeud.normal;
    if (_selection == i) return _EtatNoeud.selectionne;
    return voisins.contains(i) ? _EtatNoeud.lie : _EtatNoeud.attenue;
  }

  int _compter(int i, {required bool bon}) =>
      _aretes.where((a) => a.touche(i) && a.bon == bon).length;

  /// Whether node [i] is a good (true) or to-avoid (false) companion of the
  /// selected node, or `null` if there is no edge / it is the selection itself —
  /// drives the green/red label background in focus (tweak #1).
  bool? _relationAvecSelection(int i) {
    final sel = _selection;
    if (sel == null || sel == i) return null;
    for (final a in _aretes) {
      if (a.touche(sel) && a.autre(sel) == i) return a.bon;
    }
    return null;
  }

  /// The focus node layer: faded context bubbles plus **one grouped node per
  /// family among the selection and its links** (#2). The selected node now
  /// merges **into** its own family group — listed first with a neutral label —
  /// so a same-family companion sits beside it under a single family node (no
  /// separate "selected node" disc). Each name is tappable (the selection →
  /// opens its sheet, a link → re-focus on it); links are tinted green/red.
  List<Widget> _coucheFocus(_TransformReseau t, double rBase, Set<int> voisins) {
    final sel = _selection!;
    // Group the selection together with its links, so same-family links fuse
    // with it instead of with a standalone node (#2).
    final groupes = <String, List<int>>{};
    for (final i in {sel, ...voisins}) {
      groupes.putIfAbsent(widget.fiches[i].familleBotanique, () => []).add(i);
    }
    // List the selection first inside its own family group (neutral relation).
    for (final indices in groupes.values) {
      indices.sort((a, b) => a == sel ? -1 : (b == sel ? 1 : 0));
    }
    final fams = groupes.keys.toList()..sort();
    Offset ecran(int i) => t.versEcran(_positions[i]);

    return [
      // Faded context: non-link, non-selected bubbles (halved, dimmed).
      for (var i = 0; i < widget.fiches.length; i++)
        if (i != sel && !voisins.contains(i))
          Positioned(
            left: ecran(i).dx - rBase / 2,
            top: ecran(i).dy - rBase / 2,
            child: _Noeud(
              fiche: widget.fiches[i],
              rayon: rBase / 2,
              etat: _EtatNoeud.attenue,
              onTap: () => _toucherNoeud(i),
            ),
          ),
      // One grouped node per family (including the selection's own family), at
      // the centroid of its members.
      for (final fam in fams)
        () {
          final indices = groupes[fam]!;
          var somme = Offset.zero;
          for (final i in indices) {
            somme += _positions[i];
          }
          final p = t.versEcran(somme / indices.length.toDouble());
          return Positioned(
            left: p.dx,
            top: p.dy - _rayonNoeud - 16,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: _GroupeFocusReseau(
                famille: fam,
                especes: [for (final i in indices) widget.fiches[i]],
                relations: [for (final i in indices) _relationAvecSelection(i)],
                indices: indices,
                rayon: _rayonNoeud,
                onTapIndex: _toucherNoeud,
              ),
            ),
          );
        }(),
    ];
  }
}

/// A variety row listed under the selected species in the network view (#9),
/// opening the variety's sheet on tap. Mirrors `_LigneVariete` of the Fiches
/// view.
class _LigneVarieteReseau extends StatelessWidget {
  final FichePlante fiche;
  final void Function(FichePlante) onAjouter;

  const _LigneVarieteReseau({required this.fiche, required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: EspacementsApp.s2),
      child: InkWell(
        onTap: () =>
            afficherFichePlanteDetail(context, fiche, onAjouter: onAjouter),
        child: Padding(
          padding: const EdgeInsets.all(EspacementsApp.s3),
          child: Row(
            children: [
              Icon(
                Icons.spa_outlined,
                size: TaillesIconesApp.sm,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: EspacementsApp.s3),
              Expanded(
                child: Text(
                  fiche.nomLocalise('fr'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
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
        // Attenuated nodes (in focus) fade further so the focus reads clearly
        // (tweak #3).
        opacity: attenue ? 0.15 : 1,
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
          // The initial only fits once the zoomed disc is big enough.
          child: rayon < 10
              ? null
              : Text(
                  fiche.nomLocalise('fr').characters.first.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Full-name label shown under a node when it is selected or linked (#8a).
/// Kept at a constant on-screen size (it lives outside the zoom transform).
///
/// [relation] tints the background to show the relationship to the selection
/// (tweak #1): green for a good companion, red for one to avoid, neutral when
/// `null` (the selection itself, or the global view).
class _EtiquetteNoeud extends StatelessWidget {
  final String nom;
  final Color couleur;
  final bool? relation;

  const _EtiquetteNoeud({
    required this.nom,
    required this.couleur,
    this.relation,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final (fond, texte) = switch (relation) {
      true => (cs.primaryContainer, cs.onPrimaryContainer),
      false => (cs.errorContainer, cs.onErrorContainer),
      null => (cs.surfaceContainerHighest.withValues(alpha: 0.95), null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: const BorderRadius.all(RayonsApp.sm),
        border: Border.all(color: couleur.withValues(alpha: 0.85)),
      ),
      child: Text(
        nom,
        style: scheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: texte,
        ),
      ),
    );
  }
}

/// A grouped focus node in the constellation (dev request): when a plant is
/// selected, the members of one family collapse here — the family name above, a
/// disc (species count), and the species names below (each tappable; green/red
/// per relationship to the selection, neutral for the selection itself). The
/// selected species' own family group lists it first (#2).
class _GroupeFocusReseau extends StatelessWidget {
  final String famille;
  final List<FichePlante> especes;
  final List<bool?> relations;
  final List<int> indices;
  final double rayon;
  final void Function(int) onTapIndex;

  const _GroupeFocusReseau({
    required this.famille,
    required this.especes,
    required this.relations,
    required this.indices,
    required this.rayon,
    required this.onTapIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = couleurFamille(famille);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Family name above the node.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.all(RayonsApp.sm),
          ),
          child: Text(
            famille,
            style: theme.textTheme.labelSmall?.copyWith(
              color: couleur,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // The single disc (species count, or the initial when alone).
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
            especes.length > 1
                ? '${especes.length}'
                : especes.first.nomLocalise('fr').characters.first.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // The species list, each name tappable to re-focus on it.
        for (var k = 0; k < especes.length; k++)
          GestureDetector(
            onTap: () => onTapIndex(indices[k]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: _EtiquetteNoeud(
                nom: especes[k].nomLocalise('fr'),
                couleur: couleurCategorie(especes[k].categorie),
                relation: relations[k],
              ),
            ),
          ),
      ],
    );
  }
}

/// Overlaid display controls (#7): collapsed to a single button; opening it
/// reveals zoom in / out / recenter and the two toggles (links, family names).
/// Tapping outside closes it (like the search). Doubles the pinch gesture.
class _ControlesZoom extends StatelessWidget {
  final bool ouvert;
  final VoidCallback onOuvrir;
  final VoidCallback onFermer;
  final VoidCallback onZoomAvant;
  final VoidCallback onZoomArriere;
  final VoidCallback onRecentrer;
  final bool afficherLiens;
  final VoidCallback onToggleLiens;
  final bool afficherNoms;
  final VoidCallback onToggleNoms;

  const _ControlesZoom({
    required this.ouvert,
    required this.onOuvrir,
    required this.onFermer,
    required this.onZoomAvant,
    required this.onZoomArriere,
    required this.onRecentrer,
    required this.afficherLiens,
    required this.onToggleLiens,
    required this.afficherNoms,
    required this.onToggleNoms,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Collapsed: a single "display settings" button.
    if (!ouvert) {
      return Material(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.all(RayonsApp.md),
        elevation: 1,
        child: IconButton(
          icon: const Icon(Icons.tune),
          tooltip: l10n.reseauReglages,
          onPressed: onOuvrir,
        ),
      );
    }

    Color teinte(bool actif) =>
        actif ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return TapRegion(
      onTapOutside: (_) => onFermer(),
      child: Material(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.all(RayonsApp.md),
        elevation: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.reseauZoomAvant,
              onPressed: onZoomAvant,
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: l10n.reseauZoomArriere,
              onPressed: onZoomArriere,
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong_outlined),
              tooltip: l10n.reseauRecentrer,
              onPressed: onRecentrer,
            ),
            const Divider(height: 1, indent: 8, endIndent: 8),
            IconButton(
              icon: const Icon(Icons.polyline_outlined),
              color: teinte(afficherLiens),
              tooltip: l10n.reseauToggleLiens,
              onPressed: onToggleLiens,
            ),
            IconButton(
              icon: const Icon(Icons.label_outline),
              color: teinte(afficherNoms),
              tooltip: l10n.reseauToggleNomsFamille,
              onPressed: onToggleNoms,
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlaid name search (Lot 5): collapsed to a magnifier button (tweak #2);
/// tapping it opens the text field. Finds a species by name, selecting + framing
/// it on submit (accent/case-insensitive). Closing it returns to the global view.
class _BarreRecherche extends StatelessWidget {
  final TextEditingController controleur;
  final bool ouverte;
  final bool sansResultat;
  final VoidCallback onOuvrir;
  final ValueChanged<String> onSoumettre;
  final VoidCallback onEffacer;
  final VoidCallback onReplier;

  const _BarreRecherche({
    required this.controleur,
    required this.ouverte,
    required this.sansResultat,
    required this.onOuvrir,
    required this.onSoumettre,
    required this.onEffacer,
    required this.onReplier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Collapsed: just a magnifier button (tweak #2).
    if (!ouverte) {
      return Material(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.all(RayonsApp.md),
        elevation: 1,
        child: IconButton(
          icon: const Icon(Icons.search),
          tooltip: l10n.reseauRechercher,
          onPressed: onOuvrir,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.92),
          borderRadius: const BorderRadius.all(RayonsApp.md),
          elevation: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: TextField(
              controller: controleur,
              autofocus: true,
              textInputAction: TextInputAction.search,
              // Keep the text vertically centred in the pill (tweak #1).
              textAlignVertical: TextAlignVertical.center,
              onSubmitted: onSoumettre,
              // Tapping outside an *empty* field collapses it back to the
              // magnifier (without dropping a node selection); the close icon
              // does the full reset.
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                if (controleur.text.isEmpty) onReplier();
              },
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.reseauRechercher,
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, size: TaillesIconesApp.sm),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                // Always offers a close/clear that collapses + returns to global.
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: TaillesIconesApp.sm),
                  tooltip: l10n.catalogueEffacer,
                  onPressed: onEffacer,
                ),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EspacementsApp.s2,
                  vertical: EspacementsApp.s2,
                ),
              ),
            ),
          ),
        ),
        if (sansResultat)
          Padding(
            padding: const EdgeInsets.only(top: EspacementsApp.s1),
            child: Material(
              color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.all(RayonsApp.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EspacementsApp.s2,
                  vertical: EspacementsApp.s1,
                ),
                child: Text(
                  l10n.reseauAucunResultat,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
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
          child: Text(
            l10n.reseauAfficherEviter,
            style: theme.textTheme.bodyMedium,
          ),
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: EspacementsApp.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fiche!.nomLocalise('fr'),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${l10n.reseauNbBons(nbBons)} · ${l10n.reseauNbEviter(nbEviter)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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

/// Paints the family halos: a smooth, non-overlapping "blobby" disc per family
/// (ADR-0008). The family name sits in a pill **just above** the halo so it does
/// not collide with the bubbles inside (tweak #4). In focus, only the families
/// in [famillesAvecLabel] keep their name; the others show just the halo (tweak
/// #3). `null` means label every family (global view). Sits under edges/nodes.
class _PeintreFoyers extends CustomPainter {
  final List<FoyerFamille> foyers;
  final _TransformReseau transform;
  final Set<String>? famillesAvecLabel;
  final Color couleurFond;

  _PeintreFoyers({
    required this.foyers,
    required this.transform,
    required this.famillesAvecLabel,
    required this.couleurFond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final foyer in foyers) {
      final centre = transform.versEcran(foyer.centre);
      final rayon = foyer.rayon * transform.echelle;
      if (rayon < 4) continue; // too small to read at this zoom
      final couleur = couleurFamille(foyer.famille);
      final chemin = cheminBlobbyFamille(centre, rayon, foyer.famille);
      canvas.drawPath(chemin, Paint()..color = couleur.withValues(alpha: 0.13));
      canvas.drawPath(
        chemin,
        Paint()
          ..color = couleur.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final montrerLabel =
          famillesAvecLabel == null || famillesAvecLabel!.contains(foyer.famille);
      if (!montrerLabel) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: foyer.famille,
          style: TextStyle(
            color: couleur,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Pill just above the halo's top edge → clears the family's own bubbles
      // (tweak #4), with a translucent backing for readability over anything.
      final origine = Offset(centre.dx - tp.width / 2, centre.dy - rayon - tp.height - 4);
      final pastille = Rect.fromLTWH(
        origine.dx - 4,
        origine.dy - 2,
        tp.width + 8,
        tp.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pastille, const Radius.circular(4)),
        Paint()..color = couleurFond.withValues(alpha: 0.72),
      );
      tp.paint(canvas, origine);
    }
  }

  @override
  bool shouldRepaint(_PeintreFoyers old) =>
      old.transform != transform ||
      !identical(old.famillesAvecLabel, famillesAvecLabel);
}

/// Paints the association edges between nodes, dimming those unrelated to the
/// current selection.
class _PeintreAretes extends CustomPainter {
  final List<Offset> positions;
  final Map<int, Offset> decalages;
  final List<_Arete> aretes;
  final int? selection;
  final bool afficherAEviter;
  final _TransformReseau transform;
  final Color couleurBon;
  final Color couleurMauvais;

  _PeintreAretes({
    required this.positions,
    required this.decalages,
    required this.aretes,
    required this.selection,
    required this.afficherAEviter,
    required this.transform,
    required this.couleurBon,
    required this.couleurMauvais,
  });

  /// Screen position of node [i], honouring its #8b displacement so edges stay
  /// attached to displaced nodes.
  Offset _pos(int i) =>
      transform.versEcran(positions[i] + (decalages[i] ?? Offset.zero));

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
      canvas.drawLine(_pos(a.a), _pos(a.b), paint);
    }
  }

  @override
  bool shouldRepaint(_PeintreAretes old) =>
      old.selection != selection ||
      old.afficherAEviter != afficherAEviter ||
      old.transform != transform ||
      !identical(old.decalages, decalages);
}
