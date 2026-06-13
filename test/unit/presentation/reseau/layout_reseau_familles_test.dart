import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/reseau/layout_reseau_familles.dart';

void main() {
  // Several families of varying sizes.
  List<NoeudLayout> catalogue() => [
        for (final (f, n) in const [
          ('Solanaceae', 5),
          ('Brassicaceae', 4),
          ('Cucurbitaceae', 4),
          ('Apiaceae', 2),
          ('Lamiaceae', 1),
        ])
          for (var i = 0; i < n; i++) NoeudLayout('$f-$i', f),
      ];

  const layout = LayoutReseauFamilles();

  test('is deterministic: same input → identical positions and circles', () {
    final noeuds = catalogue();
    final a = layout.calculer(noeuds);
    final b = layout.calculer(noeuds);
    for (var i = 0; i < a.positions.length; i++) {
      expect(a.positions[i].dx, closeTo(b.positions[i].dx, 1e-9));
      expect(a.positions[i].dy, closeTo(b.positions[i].dy, 1e-9));
    }
    for (var f = 0; f < a.foyers.length; f++) {
      expect(a.foyers[f].centre.dx, closeTo(b.foyers[f].centre.dx, 1e-9));
      expect(a.foyers[f].rayon, closeTo(b.foyers[f].rayon, 1e-9));
    }
  });

  test('family circles never overlap (the core invariant)', () {
    final foyers = layout.calculer(catalogue()).foyers;
    for (var i = 0; i < foyers.length; i++) {
      for (var j = i + 1; j < foyers.length; j++) {
        final d = (foyers[i].centre - foyers[j].centre).distance;
        expect(d, greaterThanOrEqualTo(foyers[i].rayon + foyers[j].rayon - 0.5),
            reason: '${foyers[i].famille} overlaps ${foyers[j].famille}');
      }
    }
  });

  test('every species sits inside its own family circle', () {
    final res = layout.calculer(catalogue());
    for (final foyer in res.foyers) {
      for (final i in foyer.indices) {
        final d = (res.positions[i] - foyer.centre).distance;
        expect(d, lessThanOrEqualTo(foyer.rayon),
            reason: 'a ${foyer.famille} node escapes its circle');
      }
    }
  });

  test('a bigger family gets a bigger circle', () {
    final foyers = {
      for (final f in layout.calculer(catalogue()).foyers) f.famille: f,
    };
    expect(foyers['Solanaceae']!.rayon,
        greaterThan(foyers['Lamiaceae']!.rayon));
  });

  test('one foyer per family, indices partition the nodes', () {
    final noeuds = catalogue();
    final res = layout.calculer(noeuds);
    expect(res.foyers.map((f) => f.famille).toList(),
        ['Apiaceae', 'Brassicaceae', 'Cucurbitaceae', 'Lamiaceae', 'Solanaceae']);
    final tous = [for (final f in res.foyers) ...f.indices]..sort();
    expect(tous, List.generate(noeuds.length, (i) => i));
  });

  test('a single family is centred at the origin', () {
    final res = layout.calculer(const [
      NoeudLayout('a', 'Solanaceae'),
      NoeudLayout('b', 'Solanaceae'),
    ]);
    expect(res.foyers.single.centre, Offset.zero);
  });

  test('empty input yields an empty result', () {
    final res = layout.calculer(const []);
    expect(res.positions, isEmpty);
    expect(res.foyers, isEmpty);
  });
}
