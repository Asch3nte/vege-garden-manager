import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/reseau/layout_vue_associations.dart';

void main() {
  const layout = LayoutVueAssociations();
  const tailleNoeud = Size(120, 96);
  const zone = Size(400, 800);
  ResultatLayoutAssoc calc(int bons, int aEviter) => layout.calculer(
        nbBons: bons,
        nbAEviter: aEviter,
        tailleNoeud: tailleNoeud,
        zone: zone,
      );

  test('returns one position per requested node', () {
    final r = calc(7, 4);
    expect(r.bons, hasLength(7));
    expect(r.aEviter, hasLength(4));
  });

  test('empty sides yield empty lists', () {
    final r = calc(0, 0);
    expect(r.bons, isEmpty);
    expect(r.aEviter, isEmpty);
  });

  test('good companions sit left of centre, to-avoid right', () {
    final r = calc(10, 10);
    for (final p in r.bons) {
      expect(p.dx, lessThan(r.centre.dx), reason: 'bon should be on the left');
    }
    for (final p in r.aEviter) {
      expect(p.dx, greaterThan(r.centre.dx),
          reason: 'à-éviter should be on the right');
    }
  });

  void verifierSansChevauchement(List<Offset> pts) {
    // Within a ring nodes are ≥ box width apart, between rings ≥ box height;
    // the closest pair is therefore at least one box height apart → discs (and
    // fixed-width boxes) stay disjoint. Epsilon absorbs float error.
    final floor = tailleNoeud.height - 0.5;
    for (var i = 0; i < pts.length; i++) {
      for (var j = i + 1; j < pts.length; j++) {
        expect((pts[i] - pts[j]).distance, greaterThanOrEqualTo(floor),
            reason: 'nodes $i and $j overlap');
      }
    }
  }

  test('no two good companions overlap, even when crowded', () {
    verifierSansChevauchement(calc(25, 0).bons);
  });

  test('no two to-avoid overlap, even when crowded', () {
    verifierSansChevauchement(calc(0, 25).aEviter);
  });

  test('is deterministic (same input → same output)', () {
    final a = calc(12, 8);
    final b = calc(12, 8);
    expect(a.bons, b.bons);
    expect(a.aEviter, b.aEviter);
  });
}
