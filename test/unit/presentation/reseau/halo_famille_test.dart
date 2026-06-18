import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/reseau/halo_famille.dart';

void main() {
  test('graineFamille and couleurFamille are deterministic', () {
    expect(graineFamille('Solanaceae'), graineFamille('Solanaceae'));
    expect(couleurFamille('Solanaceae'), couleurFamille('Solanaceae'));
    expect(graineFamille('Solanaceae'), isNot(graineFamille('Rosaceae')));
  });

  test('blob stays within the family radius (packed families never touch)', () {
    const centre = Offset(200, 150);
    const rayon = 80.0;
    final bornes = cheminBlobbyFamille(centre, rayon, 'Cucurbitaceae').getBounds();
    // The whole contour fits inside the circle of [rayon] (inward-only wobble),
    // so two non-overlapping family circles keep their blobs disjoint.
    expect(bornes.left, greaterThanOrEqualTo(centre.dx - rayon - 0.5));
    expect(bornes.right, lessThanOrEqualTo(centre.dx + rayon + 0.5));
    expect(bornes.top, greaterThanOrEqualTo(centre.dy - rayon - 0.5));
    expect(bornes.bottom, lessThanOrEqualTo(centre.dy + rayon + 0.5));
  });

  test('the contour is the same shape for the same family (deterministic)', () {
    final a = cheminBlobbyFamille(Offset.zero, 60, 'Lamiaceae').getBounds();
    final b = cheminBlobbyFamille(Offset.zero, 60, 'Lamiaceae').getBounds();
    expect(a, b);
  });
}
