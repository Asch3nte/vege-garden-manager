import 'dart:async';
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

/// **Réseau** view of the catalogue: a constellation of plants laid out on a
/// Fermat spiral, with edges between companion (and "to avoid") plants.
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
  // viewBox of the mock-up SVG; node positions are computed in these coords then
  // scaled to the available width.
  static const double _boiteL = 312;
  static const double _boiteH = 360;
  static const Offset _centre = Offset(156, 172);
  static const double _rayonMax = 116;
  static const double _rayonNoeud = 19;

  // Zoom bounds (absolute), the +/- button step, and the cap applied when
  // fitting a small selection so a lone node doesn't zoom in absurdly (#8a).
  static const double _echelleMin = 0.4;
  static const double _echelleMax = 4.0;
  static const double _echelleAjustMax = 2.0;
  static const double _facteurZoom = 1.3;

  // Breathing room added around each label footprint during de-overlap (#8b),
  // so neighbours keep a visible gap rather than just touching.
  static const double _ecartLabel = 6.0;

  // Idle delay after the last pan/zoom before the de-overlap is recomputed once
  // (#8b): cheap, and re-spreads labels that a manual zoom-out brought together.
  static const Duration _delaiReajustement = Duration(seconds: 1);

  // Collapsed height of the network header (#10).
  static const double _enteteMin = 140.0;

  late final List<Offset> _positions;
  late final List<_Arete> _aretes;

  int? _selection;
  bool _afficherAEviter = true;

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

  // Scrolls the page; its offset collapses the network header (#10).
  final ScrollController _defilement = ScrollController();

  @override
  void initState() {
    super.initState();
    _positions = _calculerPositions(widget.fiches.length);
    _aretes = _calculerAretes(widget.fiches);
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
    _defilement.dispose();
    _ctrl.dispose();
    super.dispose();
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
        final bon =
            fiches[i].sAssocieBienAvec(fiches[j].id) ||
            fiches[j].sAssocieBienAvec(fiches[i].id);
        final mauvais =
            fiches[i].entreEnConflitAvec(fiches[j].id) ||
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
      // Frame the selection and its neighbours (#8a) and spread their labels so
      // none overlap (#8b), animating into view.
      _cadrerSelection();
    }
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

  /// Baseline transform: the viewBox (312×360) scaled to fit [vue] and centered
  /// — matching the pre-zoom layout and the "recenter" target.
  static _TransformReseau _baseline(Size vue) {
    if (vue.isEmpty) return const _TransformReseau(1, Offset.zero);
    final echelle = math.min(vue.width / _boiteL, vue.height / _boiteH);
    return _TransformReseau(
      echelle,
      Offset(
        (vue.width - _boiteL * echelle) / 2,
        (vue.height - _boiteH * echelle) / 2,
      ),
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

  /// Whether the network header has collapsed far enough to switch the nodes
  /// back to initials and drop the labels (#10).
  static const double _seuilCompact = 0.55;

  @override
  Widget build(BuildContext context) {
    // Expanded height of the network header; collapses to [_enteteMin] as the
    // list below scrolls (#10).
    final hauteurEcran = MediaQuery.sizeOf(context).height;
    final enteteMax = (hauteurEcran * 0.52).clamp(280.0, 460.0);

    final selection = _selection;
    final mere = selection == null ? null : widget.fiches[selection];
    final varietes = (mere != null && mere.estMere)
        ? widget.varietesDe(mere.id)
        : const <FichePlante>[];

    return CustomScrollView(
      controller: _defilement,
      // Drag on the network header → pan/zoom (its own gesture). Drag on the
      // list below → scroll, which collapses the header (#7 vs #10).
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _EnteteReseau(
            min: _enteteMin,
            max: enteteMax,
            constructeur: _construireCanvas,
            seuilCompact: _seuilCompact,
            // Recreated each build → the header reflects the current selection,
            // transform and displacements.
            signature: Object.hash(_selection, _transform, _afficherAEviter),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              EspacementsApp.s4,
              EspacementsApp.s2,
              EspacementsApp.s4,
              0,
            ),
            child: Column(
              children: [
                _BarreAEviter(
                  valeur: _afficherAEviter,
                  onChanged: (v) {
                    setState(() => _afficherAEviter = v);
                    // The named set (links) changed → re-spread labels at the
                    // current view so none overlap (#8b).
                    if (_selection != null) {
                      _recadrer(_transformActuel(_viewport));
                    }
                  },
                ),
                const SizedBox(height: EspacementsApp.s3),
                _Panneau(
                  fiche: mere,
                  nbBons: selection == null
                      ? 0
                      : _compter(selection, bon: true),
                  nbEviter: selection == null
                      ? 0
                      : _compter(selection, bon: false),
                  onVoirFiche: mere == null ? null : () => _ouvrirFiche(mere),
                ),
              ],
            ),
          ),
        ),
        // Varieties of the selected species (#9).
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            EspacementsApp.s4,
            EspacementsApp.s3,
            EspacementsApp.s4,
            EspacementsApp.s4,
          ),
          sliver: SliverList.list(
            children: [
              for (final v in varietes)
                _LigneVarieteReseau(fiche: v, onAjouter: widget.onAjouter),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the interactive constellation canvas (#7/#8). In [compact] mode the
  /// nodes show their initial and the full-name labels are dropped (#10).
  Widget _construireCanvas(BuildContext context, bool compact) {
    final theme = Theme.of(context);
    final voisins = _selection == null ? const <int>{} : _voisins(_selection!);
    // Selected node + its links — drives the highlight and paint order.
    final surlignes = _selection == null
        ? const <int>{}
        : {_selection!, ...voisins};
    // Nodes shown with their full name (#8a) — none while collapsed (#10).
    final nommes = compact ? const <int>{} : surlignes;
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
        _viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final t = _transformActuel(_viewport);

        // The whole canvas pans/zooms; the gesture arena lets node taps and the
        // controls win their own taps, while drags pan/zoom.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _debutGeste,
          onScaleUpdate: _majGeste,
          child: ClipRect(
            child: Stack(
              children: [
                CustomPaint(
                  size: _viewport,
                  painter: _PeintreAretes(
                    positions: _positions,
                    decalages: _decalages,
                    aretes: _aretes,
                    selection: _selection,
                    afficherAEviter: _afficherAEviter,
                    transform: t,
                    couleurBon: theme.colorScheme.primary,
                    couleurMauvais: theme.colorScheme.error,
                  ),
                ),
                for (final i in ordreNoeuds)
                  Positioned(
                    left: t.versEcran(_posAffichee(i)).dx - _rayonNoeud,
                    top: t.versEcran(_posAffichee(i)).dy - _rayonNoeud,
                    child: _Noeud(
                      fiche: widget.fiches[i],
                      rayon: _rayonNoeud,
                      etat: _etatNoeud(i, voisins),
                      onTap: () => _toucherNoeud(i),
                    ),
                  ),
                // Full-name labels under the selected node and its links (#8a).
                // Centered on each node via a -50%-width shift, so the label
                // width never offsets the node; constant on-screen size whatever
                // the zoom. Ignores pointers so the node stays tappable/pannable.
                for (final i in nommes)
                  Positioned(
                    left: t.versEcran(_posAffichee(i)).dx,
                    top: t.versEcran(_posAffichee(i)).dy + _rayonNoeud + 2,
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
                Positioned(
                  top: EspacementsApp.s2,
                  right: EspacementsApp.s2,
                  child: _ControlesZoom(
                    onZoomAvant: () => _zoomer(_facteurZoom),
                    onZoomArriere: () => _zoomer(1 / _facteurZoom),
                    onRecentrer: _recentrer,
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
}

/// Collapsing header hosting the interactive constellation (#10).
///
/// Shrinks from [max] to [min] as the list below scrolls; past [seuilCompact]
/// of the travel it asks the canvas for the compact (initials, no labels) form.
class _EnteteReseau extends SliverPersistentHeaderDelegate {
  final double min;
  final double max;
  final double seuilCompact;
  final Widget Function(BuildContext context, bool compact) constructeur;

  /// Hash of the host state that affects the rendered canvas; drives
  /// [shouldRebuild] so the header refreshes on selection/zoom changes.
  final int signature;

  _EnteteReseau({
    required this.min,
    required this.max,
    required this.seuilCompact,
    required this.constructeur,
    required this.signature,
  });

  @override
  double get minExtent => min;

  @override
  double get maxExtent => max;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final progression = max > min ? (shrinkOffset / (max - min)) : 0.0;
    final compact = progression >= seuilCompact;
    return SizedBox.expand(child: constructeur(context, compact));
  }

  @override
  bool shouldRebuild(_EnteteReseau old) =>
      old.min != min ||
      old.max != max ||
      old.seuilCompact != seuilCompact ||
      old.signature != signature;
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
class _EtiquetteNoeud extends StatelessWidget {
  final String nom;
  final Color couleur;

  const _EtiquetteNoeud({required this.nom, required this.couleur});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.95,
        ),
        borderRadius: const BorderRadius.all(RayonsApp.sm),
        border: Border.all(color: couleur.withValues(alpha: 0.85)),
      ),
      child: Text(
        nom,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Overlaid zoom controls (#7): zoom in / out / recenter. Doubles the pinch
/// gesture for desktop/mouse users.
class _ControlesZoom extends StatelessWidget {
  final VoidCallback onZoomAvant;
  final VoidCallback onZoomArriere;
  final VoidCallback onRecentrer;

  const _ControlesZoom({
    required this.onZoomAvant,
    required this.onZoomArriere,
    required this.onRecentrer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Material(
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
        ],
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
          TextButton(onPressed: onVoirFiche, child: Text(l10n.reseauVoirFiche)),
        ],
      ),
    );
  }
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
