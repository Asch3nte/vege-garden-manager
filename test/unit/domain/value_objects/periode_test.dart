import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';

void main() {
  group('Periode — construction & invariants', () {
    test('exposes its bounds', () {
      const p = Periode(5, 8);
      expect(p.moisDebut, 5);
      expect(p.moisFin, 8);
    });

    test('rejects a start month outside 1..12', () {
      expect(() => Periode(0, 6), throwsA(isA<AssertionError>()));
      expect(() => Periode(13, 6), throwsA(isA<AssertionError>()));
    });

    test('rejects an end month outside 1..12', () {
      expect(() => Periode(6, 0), throwsA(isA<AssertionError>()));
      expect(() => Periode(6, 13), throwsA(isA<AssertionError>()));
    });
  });

  group('Periode — year wrap detection', () {
    test('a normal range does not wrap', () {
      expect(const Periode(3, 9).chevaucheAnnee, isFalse);
    });

    test('a range with start after end wraps', () {
      expect(const Periode(11, 2).chevaucheAnnee, isTrue);
    });

    test('a single-month period does not wrap', () {
      expect(const Periode(6, 6).chevaucheAnnee, isFalse);
    });
  });

  group('Periode — dureeEnMois', () {
    test('normal range counts both bounds', () {
      expect(const Periode(3, 5).dureeEnMois, 3);
    });

    test('full year', () {
      expect(const Periode(1, 12).dureeEnMois, 12);
    });

    test('single month', () {
      expect(const Periode(6, 6).dureeEnMois, 1);
    });

    test('wrapping range (Nov→Feb) counts 4 months', () {
      expect(const Periode(11, 2).dureeEnMois, 4);
    });
  });

  group('Periode — contientMois (normal range)', () {
    const p = Periode(5, 8); // May → August

    test('includes the bounds', () {
      expect(p.contientMois(5), isTrue);
      expect(p.contientMois(8), isTrue);
    });

    test('includes a month inside', () {
      expect(p.contientMois(6), isTrue);
    });

    test('excludes months outside', () {
      expect(p.contientMois(4), isFalse);
      expect(p.contientMois(9), isFalse);
    });
  });

  group('Periode — contientMois (wrapping range)', () {
    const p = Periode(11, 2); // November → February

    test('includes months on both sides of the year boundary', () {
      expect(p.contientMois(11), isTrue);
      expect(p.contientMois(12), isTrue);
      expect(p.contientMois(1), isTrue);
      expect(p.contientMois(2), isTrue);
    });

    test('excludes months in the middle of the year', () {
      expect(p.contientMois(3), isFalse);
      expect(p.contientMois(7), isFalse);
      expect(p.contientMois(10), isFalse);
    });
  });

  group('Periode — contient(DateTime)', () {
    test('uses the month of the date', () {
      const p = Periode(11, 2);
      expect(p.contient(DateTime(2026, 1, 15)), isTrue);
      expect(p.contient(DateTime(2026, 7, 1)), isFalse);
    });
  });

  group('Periode — equality by value', () {
    test('same bounds are equal and share a hashCode', () {
      expect(const Periode(3, 6), const Periode(3, 6));
      expect(
        const Periode(3, 6).hashCode,
        const Periode(3, 6).hashCode,
      );
    });

    test('different bounds are not equal', () {
      expect(const Periode(3, 6) == const Periode(3, 7), isFalse);
      expect(const Periode(3, 6) == const Periode(6, 3), isFalse);
    });
  });
}
