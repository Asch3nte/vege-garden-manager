import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

void main() {
  group('Surface — construction & conversions', () {
    test('enMetresCarres exposes the value in m²', () {
      final s = Surface.enMetresCarres(2.5);
      expect(s.enMetresCarres, 2.5);
    });

    test('enCentimetresCarres converts cm² to m² (10000 cm² = 1 m²)', () {
      final s = Surface.enCentimetresCarres(10000);
      expect(s.enMetresCarres, 1.0);
    });

    test('enCentimetresCarres getter converts m² back to cm²', () {
      final s = Surface.enMetresCarres(1);
      expect(s.enCentimetresCarres, 10000);
    });

    test('zero is a neutral, zero-area surface', () {
      expect(Surface.zero.enMetresCarres, 0);
    });

    test('a negative surface is rejected at construction', () {
      expect(() => Surface.enMetresCarres(-1), throwsA(isA<AssertionError>()));
      expect(
        () => Surface.enCentimetresCarres(-1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Surface — arithmetic', () {
    test('addition sums the areas', () {
      final result = Surface.enMetresCarres(2) + Surface.enMetresCarres(3);
      expect(result, Surface.enMetresCarres(5));
    });

    test('subtraction returns the difference', () {
      final result = Surface.enMetresCarres(5) - Surface.enMetresCarres(2);
      expect(result, Surface.enMetresCarres(3));
    });

    test('subtracting a larger surface violates the non-negative invariant', () {
      expect(
        () => Surface.enMetresCarres(2) - Surface.enMetresCarres(5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('zero is the identity element for addition', () {
      final s = Surface.enMetresCarres(4);
      expect(s + Surface.zero, s);
    });
  });

  group('Surface — comparisons', () {
    final small = Surface.enMetresCarres(1);
    final big = Surface.enMetresCarres(2);

    test('>= and <=', () {
      expect(big >= small, isTrue);
      expect(small <= big, isTrue);
      expect(small >= small, isTrue);
    });

    test('> and <', () {
      expect(big > small, isTrue);
      expect(small < big, isTrue);
      expect(small > big, isFalse);
    });

    test('compareTo orders surfaces by area', () {
      final list = [big, small, Surface.zero]..sort();
      expect(list, [Surface.zero, small, big]);
    });
  });

  group('Surface — equality by value', () {
    test('two surfaces describing the same area are equal', () {
      expect(
        Surface.enMetresCarres(1),
        Surface.enCentimetresCarres(10000),
      );
    });

    test('equal surfaces share the same hashCode', () {
      expect(
        Surface.enMetresCarres(1).hashCode,
        Surface.enCentimetresCarres(10000).hashCode,
      );
    });

    test('different areas are not equal', () {
      expect(Surface.enMetresCarres(1) == Surface.enMetresCarres(2), isFalse);
    });
  });
}
