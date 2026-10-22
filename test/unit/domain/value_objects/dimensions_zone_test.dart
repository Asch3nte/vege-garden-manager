import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/exceptions/invariant_domaine_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/dimensions_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

void main() {
  group('DimensionsZone', () {
    test('exposes its sides in centimetres', () {
      final d = DimensionsZone(longueurCm: 300, largeurCm: 120);
      expect(d.longueurCm, 300);
      expect(d.largeurCm, 120);
    });

    test('surface is length times width', () {
      final d = DimensionsZone(longueurCm: 300, largeurCm: 120);
      expect(d.surface, Surface.enMetresCarres(3.6));
    });

    test('rejects a side that is not positive', () {
      expect(() => DimensionsZone(longueurCm: 0, largeurCm: 120),
          throwsA(isA<InvariantDomaineException>()));
      expect(() => DimensionsZone(longueurCm: 300, largeurCm: -1),
          throwsA(isA<InvariantDomaineException>()));
    });

    test('keeps fractional centimetres', () {
      final d = DimensionsZone(longueurCm: 304.8, largeurCm: 121.92);
      expect(d.surface.enMetresCarres, closeTo(3.7161216, 1e-9));
    });

    test('equality by value', () {
      expect(DimensionsZone(longueurCm: 300, largeurCm: 120),
          DimensionsZone(longueurCm: 300, largeurCm: 120));
      expect(DimensionsZone(longueurCm: 300, largeurCm: 120),
          isNot(DimensionsZone(longueurCm: 120, largeurCm: 300)));
    });
  });
}
