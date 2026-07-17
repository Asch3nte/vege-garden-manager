import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/value_objects/fenetre_ne_pas_deranger.dart';

void main() {
  group('FenetreNePasDeranger — construction & invariants', () {
    test('exposes its bounds', () {
      const f = FenetreNePasDeranger(1320, 420); // 22:00 → 07:00
      expect(f.debutMinutes, 1320);
      expect(f.finMinutes, 420);
    });

    test('rejects bounds outside 0..1439', () {
      expect(() => FenetreNePasDeranger(-1, 420), throwsA(isA<AssertionError>()));
      expect(() => FenetreNePasDeranger(1320, 1440), throwsA(isA<AssertionError>()));
    });
  });

  group('FenetreNePasDeranger.depuisHeures — parsing', () {
    test('parses valid HH:MM bounds', () {
      final f = FenetreNePasDeranger.depuisHeures('22:00', '07:30');
      expect(f, isNotNull);
      expect(f!.debutMinutes, 22 * 60);
      expect(f.finMinutes, 7 * 60 + 30);
    });

    test('returns null when either bound is null (disabled)', () {
      expect(FenetreNePasDeranger.depuisHeures(null, '07:00'), isNull);
      expect(FenetreNePasDeranger.depuisHeures('22:00', null), isNull);
      expect(FenetreNePasDeranger.depuisHeures(null, null), isNull);
    });

    test('returns null on malformed input (robust read, no throw)', () {
      expect(FenetreNePasDeranger.depuisHeures('nope', '07:00'), isNull);
      expect(FenetreNePasDeranger.depuisHeures('25:00', '07:00'), isNull);
      expect(FenetreNePasDeranger.depuisHeures('22:60', '07:00'), isNull);
      expect(FenetreNePasDeranger.depuisHeures('2200', '07:00'), isNull);
      expect(FenetreNePasDeranger.depuisHeures('', ''), isNull);
    });
  });

  group('FenetreNePasDeranger — midnight wrap detection', () {
    test('an evening→morning window wraps', () {
      expect(const FenetreNePasDeranger(1320, 420).chevaucheMinuit, isTrue);
    });

    test('a same-day window does not wrap', () {
      expect(const FenetreNePasDeranger(540, 1020).chevaucheMinuit, isFalse);
    });
  });

  group('FenetreNePasDeranger.contient — wrapping window 22:00→07:00', () {
    final f = FenetreNePasDeranger.depuisHeures('22:00', '07:00')!;
    DateTime at(int h, int m) => DateTime(2026, 7, 17, h, m);

    test('includes late evening', () {
      expect(f.contient(at(23, 30)), isTrue);
    });

    test('includes early morning', () {
      expect(f.contient(at(3, 0)), isTrue);
    });

    test('start bound is inside (half-open lower)', () {
      expect(f.contient(at(22, 0)), isTrue);
    });

    test('end bound is outside (half-open upper)', () {
      expect(f.contient(at(7, 0)), isFalse);
    });

    test('excludes daytime (08:00)', () {
      expect(f.contient(at(8, 0)), isFalse);
    });
  });

  group('FenetreNePasDeranger.contient — same-day window 09:00→17:00', () {
    final f = FenetreNePasDeranger.depuisHeures('09:00', '17:00')!;
    DateTime at(int h, int m) => DateTime(2026, 7, 17, h, m);

    test('includes midday, excludes night', () {
      expect(f.contient(at(12, 0)), isTrue);
      expect(f.contient(at(8, 59)), isFalse);
      expect(f.contient(at(17, 0)), isFalse);
      expect(f.contient(at(2, 0)), isFalse);
    });
  });

  group('FenetreNePasDeranger.contient — degenerate equal bounds', () {
    test('covers nothing', () {
      const f = FenetreNePasDeranger(420, 420);
      expect(f.contient(DateTime(2026, 7, 17, 7, 0)), isFalse);
      expect(f.contient(DateTime(2026, 7, 17, 12, 0)), isFalse);
    });
  });

  group('FenetreNePasDeranger — equality', () {
    test('equal by value', () {
      expect(const FenetreNePasDeranger(1320, 420),
          const FenetreNePasDeranger(1320, 420));
      expect(const FenetreNePasDeranger(1320, 420).hashCode,
          const FenetreNePasDeranger(1320, 420).hashCode);
      expect(const FenetreNePasDeranger(1320, 420),
          isNot(const FenetreNePasDeranger(1320, 421)));
    });
  });
}
