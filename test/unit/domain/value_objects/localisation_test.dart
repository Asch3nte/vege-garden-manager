import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/source_localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';

void main() {
  group('Localisation — nonDefinie (opt-out)', () {
    test('has no coordinates and the nonDefinie source', () {
      const loc = Localisation.nonDefinie();
      expect(loc.estDefinie, isFalse);
      expect(loc.latitude, isNull);
      expect(loc.longitude, isNull);
      expect(loc.ville, isNull);
      expect(loc.source, SourceLocalisation.nonDefinie);
    });
  });

  group('Localisation — manuelle', () {
    test('keeps the city and marks the source as manuelle', () {
      final loc = Localisation.manuelle(
        ville: 'Nantes',
        latitude: 47.21,
        longitude: -1.55,
      );
      expect(loc.estDefinie, isTrue);
      expect(loc.ville, 'Nantes');
      expect(loc.source, SourceLocalisation.manuelle);
    });
  });

  group('Localisation — gps', () {
    test('has coordinates, no city, source gps', () {
      final loc = Localisation.gps(latitude: 48.85, longitude: 2.35);
      expect(loc.estDefinie, isTrue);
      expect(loc.ville, isNull);
      expect(loc.source, SourceLocalisation.gps);
    });
  });

  group('Localisation — privacy rounding (~1 km)', () {
    test('full-precision coordinates are rounded to 2 decimals', () {
      final loc = Localisation.gps(
        latitude: 48.85661234,
        longitude: 2.35221999,
      );
      expect(loc.latitude, 48.86);
      expect(loc.longitude, 2.35);
    });

    test('negative coordinates round to nearest', () {
      final loc = Localisation.manuelle(
        ville: 'Quito',
        latitude: -0.180653,
        longitude: -78.467834,
      );
      expect(loc.latitude, -0.18);
      expect(loc.longitude, -78.47);
    });
  });

  group('Localisation — coordinate validation', () {
    test('rejects out-of-range latitude', () {
      expect(
        () => Localisation.gps(latitude: 91, longitude: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Localisation.manuelle(ville: 'X', latitude: -91, longitude: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects out-of-range longitude', () {
      expect(
        () => Localisation.gps(latitude: 0, longitude: 181),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Localisation — equality by value', () {
    test('two undefined locations are equal', () {
      expect(const Localisation.nonDefinie(), const Localisation.nonDefinie());
    });

    test('same rounded coordinates, city and source are equal', () {
      final a = Localisation.manuelle(
        ville: 'Nantes',
        latitude: 47.213,
        longitude: -1.554,
      );
      final b = Localisation.manuelle(
        ville: 'Nantes',
        latitude: 47.214, // rounds to the same 47.21
        longitude: -1.552,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('same coordinates but different source are not equal', () {
      final manual = Localisation.manuelle(
        ville: 'V',
        latitude: 48.85,
        longitude: 2.35,
      );
      final gps = Localisation.gps(latitude: 48.85, longitude: 2.35);
      expect(manual == gps, isFalse);
    });
  });
}
