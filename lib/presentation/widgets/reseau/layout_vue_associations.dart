import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

/// Result of an Associations ego-layout: the [centre] and the positions of the
/// good companions ([bons], left half-plane) and the to-avoid ones ([aEviter],
/// right half-plane). One position per requested node, **box-overlap free**.
class ResultatLayoutAssoc {
  final Offset centre;
  final List<Offset> bons;
  final List<Offset> aEviter;

  const ResultatLayoutAssoc({
    required this.centre,
    required this.bons,
    required this.aEviter,
  });
}

/// Tunables of [LayoutVueAssociations].
class ParametresLayoutAssoc {
  /// Extra gap (px) kept between two boxes tangentially (same ring).
  final double gapTangentiel;

  /// Extra gap (px) kept between two rings.
  final double gapRadial;

  /// Radius (px) reserved for the centre node before the first ring.
  final double rayonCentre;

  /// Fraction of a half-turn (π) actually used by a side, < 1 so good (left) and
  /// to-avoid (right) never meet on the vertical axis.
  final double fractionDemiTour;

  const ParametresLayoutAssoc({
    this.gapTangentiel = 12,
    this.gapRadial = 16,
    this.rayonCentre = 30,
    this.fractionDemiTour = 0.9,
  });
}

/// Pure, deterministic ego-layout for the Associations view (ADR-0012).
///
/// Concentric **rings per half-plane** (good left, to-avoid right): each ring is
/// filled to capacity (how many node-boxes fit in its 180° at that radius), the
/// surplus going to outer rings. Every other ring is **staggered by half a slot**
/// so an outer node sits between the inner ones — discs never overlap and an
/// edge to an outer node passes in the gap rather than through an inner bubble.
/// Math only (no widgets), reproducible, so it is unit-testable against any node
/// count.
class LayoutVueAssociations {
  final ParametresLayoutAssoc parametres;

  const LayoutVueAssociations({this.parametres = const ParametresLayoutAssoc()});

  /// Places [nbBons] good companions (left) and [nbAEviter] to-avoid (right)
  /// around the centre of [zone], each node occupying a [tailleNoeud] box.
  ResultatLayoutAssoc calculer({
    required int nbBons,
    required int nbAEviter,
    required Size tailleNoeud,
    required Size zone,
  }) {
    final centre = Offset(zone.width / 2, zone.height / 2);
    return ResultatLayoutAssoc(
      centre: centre,
      bons: _placerCote(nbBons, gauche: true, t: tailleNoeud, centre: centre),
      aEviter:
          _placerCote(nbAEviter, gauche: false, t: tailleNoeud, centre: centre),
    );
  }

  List<Offset> _placerCote(
    int n, {
    required bool gauche,
    required Size t,
    required Offset centre,
  }) {
    if (n <= 0) return const [];
    final span = math.pi * parametres.fractionDemiTour;
    // Tangential = box width, radial = box height (tighter than the diagonal):
    // fill each ring to capacity, surplus to outer rings.
    final pasTangentiel = t.width + parametres.gapTangentiel;
    final pasRadial = t.height + parametres.gapRadial;
    final rMin = parametres.rayonCentre + t.height / 2 + pasRadial;
    // Left side fans around π (pointing left); right side around 0.
    final angleCentre = gauche ? math.pi : 0.0;

    final positions = <Offset>[];
    var reste = n;
    var anneau = 0;
    while (reste > 0) {
      final r = rMin + anneau * pasRadial;
      final capacite = math.max(1, (span * r / pasTangentiel).floor());
      final cnt = math.min(reste, capacite);
      // Stagger every other ring by half a slot so an outer node sits *between*
      // the inner ones — its edge then passes in the gap, not through a bubble.
      final demiPas = anneau.isOdd ? 0.5 / cnt : 0.0;
      for (var i = 0; i < cnt; i++) {
        final frac = (i + 0.5) / cnt + demiPas;
        final angle = angleCentre + (frac - 0.5) * span;
        positions.add(centre + Offset.fromDirection(angle, r));
      }
      reste -= cnt;
      anneau++;
    }
    return positions;
  }
}
