import 'dart:math' as math;
import 'dart:ui' show Offset;

/// One node fed to the layout: a stable [id] and the botanical [famille] it
/// belongs to (the clustering key, ADR-0008).
class NoeudLayout {
  final String id;
  final String famille;

  const NoeudLayout(this.id, this.famille);
}

/// A family's footprint: the member node [indices], the circle [centre] and its
/// [rayon]. Family circles are **packed without overlap**, so a family is always
/// a smooth disc that never intersects another (ADR-0008). The label sits inside
/// the top of the circle.
class FoyerFamille {
  final String famille;
  final List<int> indices;
  final Offset centre;
  final double rayon;

  const FoyerFamille({
    required this.famille,
    required this.indices,
    required this.centre,
    required this.rayon,
  });
}

/// The result of a layout run: a [positions] entry per input node (virtual
/// coordinates, same order as the input) and one [foyers] entry per family.
class ResultatLayout {
  final List<Offset> positions;
  final List<FoyerFamille> foyers;

  const ResultatLayout({required this.positions, required this.foyers});
}

/// Tunable constants of the layout. Defaults are a starting point — the preview
/// harness exists to tune them against real data (ADR-0008).
class ParametresLayout {
  /// Spacing between two species inside a family's circle (phyllotaxis step).
  final double espacementNoeud;

  /// Padding added around the inner cloud to size a family's circle (room for
  /// the node discs, the label and the halo border).
  final double margeFamille;

  /// Minimum radius of a family circle (so a lone-species family is not tiny).
  final double rayonMinFamille;

  /// Clear gap kept between two family circles when packing (so bubbles read as
  /// separate, never kissing).
  final double ecartFamilles;

  /// Relaxation iterations of the bubble packing (fixed → deterministic).
  final int iterationsPacking;

  const ParametresLayout({
    this.espacementNoeud = 30,
    this.margeFamille = 30,
    this.rayonMinFamille = 46,
    this.ecartFamilles = 12,
    this.iterationsPacking = 600,
  });
}

/// Deterministic **bubble** layout clustering nodes by botanical family
/// (ADR-0008, Décision 2, révisée après prototype).
///
/// Each family is a **circle** whose radius grows with its member count; the
/// circles are **packed without overlap** (a family never intersects another →
/// smooth, angle-free halos). Inside a circle, species are placed on a
/// phyllotaxis (sunflower) spiral — an even, natural distribution. Cross-family
/// association edges are drawn as plain lines and play no part in placement
/// (keeping families disjoint takes precedence over pulling linked species
/// together).
///
/// Pure and reproducible: family order, inner placement and packing are all
/// deterministic (no randomness), and computed **once** (static solve), never
/// animated live — the user's spatial memory is preserved across launches.
class LayoutReseauFamilles {
  final ParametresLayout parametres;

  const LayoutReseauFamilles({this.parametres = const ParametresLayout()});

  /// Computes positions for [noeuds]. The association [aretes] are accepted for
  /// API symmetry but do not influence placement (see class doc).
  ResultatLayout calculer(
    List<NoeudLayout> noeuds, [
    List<(int, int)> aretes = const [],
  ]) {
    if (noeuds.isEmpty) {
      return const ResultatLayout(positions: [], foyers: []);
    }

    final familles = _indexerFamilles(noeuds);

    // 1. Inner placement + radius for each family (local coords, centred on 0).
    final placementsLocaux = <String, List<Offset>>{};
    final rayons = <String, double>{};
    for (final entree in familles.entries) {
      final locaux = _placementInterne(entree.value.length);
      placementsLocaux[entree.key] = locaux;
      rayons[entree.key] = _rayonFamille(locaux);
    }

    // 2. Pack the family circles without overlap → a centre per family.
    final centres = _packerFamilles(familles.keys.toList(), rayons);

    // 3. Project members to world coords and build the foyers.
    final positions = List<Offset>.filled(noeuds.length, Offset.zero);
    final foyers = <FoyerFamille>[];
    for (final entree in familles.entries) {
      final centre = centres[entree.key]!;
      final locaux = placementsLocaux[entree.key]!;
      for (var k = 0; k < entree.value.length; k++) {
        positions[entree.value[k]] = centre + locaux[k];
      }
      foyers.add(FoyerFamille(
        famille: entree.key,
        indices: entree.value,
        centre: centre,
        rayon: rayons[entree.key]!,
      ));
    }

    return ResultatLayout(positions: positions, foyers: foyers);
  }

  /// Groups node indices by family, families ordered deterministically by name.
  Map<String, List<int>> _indexerFamilles(List<NoeudLayout> noeuds) {
    final familles = <String, List<int>>{};
    for (var i = 0; i < noeuds.length; i++) {
      familles.putIfAbsent(noeuds[i].famille, () => []).add(i);
    }
    return {
      for (final f in familles.keys.toList()..sort()) f: familles[f]!,
    };
  }

  /// Phyllotaxis (golden-angle) placement of [n] species, centred on its
  /// centroid so the cloud sits around the origin.
  List<Offset> _placementInterne(int n) {
    if (n == 1) return const [Offset.zero];
    final ga = math.pi * (3 - math.sqrt(5));
    final pts = [
      for (var k = 0; k < n; k++)
        Offset.fromDirection(
          k * ga,
          parametres.espacementNoeud * math.sqrt(k + 0.5),
        ),
    ];
    final centroide = pts.reduce((a, b) => a + b) / n.toDouble();
    return [for (final p in pts) p - centroide];
  }

  /// Radius enclosing the inner cloud [locaux], plus margin (and a floor).
  double _rayonFamille(List<Offset> locaux) {
    var max = 0.0;
    for (final p in locaux) {
      max = math.max(max, p.distance);
    }
    return math.max(parametres.rayonMinFamille, max + parametres.margeFamille);
  }

  /// Packs the family circles ([rayons] by family) with no overlap, deterministic.
  ///
  /// Largest families first, seeded on a golden-angle spiral, then relaxed by
  /// collision separation + mild gravity (for compactness). A final
  /// separation-only pass **guarantees** the no-overlap invariant before exit.
  Map<String, Offset> _packerFamilles(
    List<String> familles,
    Map<String, double> rayons,
  ) {
    if (familles.length == 1) {
      return {familles.first: Offset.zero};
    }

    // Largest first → tighter packing; ties broken by name for determinism.
    final ordre = [...familles]..sort((a, b) {
        final cmp = rayons[b]!.compareTo(rayons[a]!);
        return cmp != 0 ? cmp : a.compareTo(b);
      });

    final ga = math.pi * (3 - math.sqrt(5));
    final rayonMax = rayons.values.reduce(math.max);
    final centres = <String, Offset>{};
    for (var k = 0; k < ordre.length; k++) {
      // Seed on a spreading spiral so no two circles start coincident.
      centres[ordre[k]] = Offset.fromDirection(k * ga, (k + 1) * rayonMax * 0.6);
    }

    final ecart = parametres.ecartFamilles;
    void separer(double force) {
      for (var i = 0; i < ordre.length; i++) {
        for (var j = i + 1; j < ordre.length; j++) {
          final a = ordre[i], b = ordre[j];
          var delta = centres[b]! - centres[a]!;
          var dist = delta.distance;
          final mini = rayons[a]! + rayons[b]! + ecart;
          if (dist >= mini) continue;
          if (dist < 1e-6) {
            // Coincident → split deterministically along x.
            delta = Offset(1e-3 * (i + 1), 0);
            dist = delta.distance;
          }
          final pousse = delta / dist * ((mini - dist) / 2 * force);
          centres[a] = centres[a]! - pousse;
          centres[b] = centres[b]! + pousse;
        }
      }
    }

    // Relax: separation + gravity toward the centroid for a compact cluster.
    for (var iter = 0; iter < parametres.iterationsPacking; iter++) {
      separer(1);
      final centroide =
          centres.values.reduce((a, b) => a + b) / ordre.length.toDouble();
      for (final f in ordre) {
        centres[f] = centres[f]! - (centres[f]! - centroide) * 0.02;
      }
    }
    // Guarantee the invariant: separation-only until nothing overlaps.
    for (var garde = 0; garde < 200; garde++) {
      var propre = true;
      for (var i = 0; i < ordre.length && propre; i++) {
        for (var j = i + 1; j < ordre.length; j++) {
          final d = (centres[ordre[j]]! - centres[ordre[i]]!).distance;
          if (d < rayons[ordre[i]]! + rayons[ordre[j]]! + ecart - 0.5) {
            propre = false;
            break;
          }
        }
      }
      if (propre) break;
      separer(1);
    }
    return centres;
  }
}
