import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/selecteur_carte_monde.dart';

void main() {
  group('ProjectionEquirectangulaire — versCoords', () {
    test('top-left fraction is (-180, +90)', () {
      final (lat, lon) = ProjectionEquirectangulaire.versCoords(0, 0);
      expect(lat, 90);
      expect(lon, -180);
    });

    test('centre fraction is (0, 0)', () {
      final (lat, lon) = ProjectionEquirectangulaire.versCoords(0.5, 0.5);
      expect(lat, 0);
      expect(lon, 0);
    });

    test('bottom-right fraction is (+180, -90)', () {
      final (lat, lon) = ProjectionEquirectangulaire.versCoords(1, 1);
      expect(lat, -90);
      expect(lon, 180);
    });

    test('out-of-range fractions are clamped to the edges', () {
      final (lat, lon) = ProjectionEquirectangulaire.versCoords(1.5, -0.2);
      expect(lat, 90);
      expect(lon, 180);
    });
  });

  group('ProjectionEquirectangulaire — versFraction', () {
    test('(0, 0) maps to the centre', () {
      final (fx, fy) = ProjectionEquirectangulaire.versFraction(0, 0);
      expect(fx, 0.5);
      expect(fy, 0.5);
    });

    test('round-trips an arbitrary coordinate', () {
      const lat = 48.2;
      const lon = 2.4;
      final (fx, fy) = ProjectionEquirectangulaire.versFraction(lat, lon);
      final (lat2, lon2) = ProjectionEquirectangulaire.versCoords(fx, fy);
      expect(lat2, closeTo(lat, 1e-9));
      expect(lon2, closeTo(lon, 1e-9));
    });
  });
}
