import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/globe/projection_orthographique.dart';

void main() {
  const proj = ProjectionOrthographique(latitudeCentre: 50, longitudeCentre: 4);

  test('the disc centre is the view centre', () {
    final (lat, lon) = proj.versCoords(Offset.zero)!;
    expect(lat, closeTo(50, 1e-9));
    expect(lon, closeTo(4, 1e-9));
    expect(proj.versDisque(50, 4), const Offset(0, 0));
  });

  test('up on screen is north, right is east', () {
    final (latHaut, _) = proj.versCoords(const Offset(0, -0.3))!;
    final (_, lonDroite) = proj.versCoords(const Offset(0.3, 0))!;
    expect(latHaut, greaterThan(50));
    expect(lonDroite, greaterThan(4));
  });

  test('points outside the disc have no coordinates', () {
    expect(proj.versCoords(const Offset(0.8, 0.8)), isNull);
  });

  test('forward and inverse projections agree', () {
    for (final p in const [
      Offset(0.5, 0.2),
      Offset(-0.7, -0.6),
      Offset(0.1, 0.95),
    ]) {
      final (lat, lon) = proj.versCoords(p)!;
      final q = proj.versDisque(lat, lon)!;
      expect(q.dx, closeTo(p.dx, 1e-9));
      expect(q.dy, closeTo(p.dy, 1e-9));
    }
  });

  test('the far side is hidden', () {
    expect(proj.versDisque(-50, -176), isNull);
  });

  test('longitudes wrap across the antimeridian', () {
    const pacifique =
        ProjectionOrthographique(latitudeCentre: 0, longitudeCentre: 179);
    final (_, lon) = pacifique.versCoords(const Offset(0.2, 0))!;
    expect(lon, closeTo(-169.46, 0.01));
  });
}
