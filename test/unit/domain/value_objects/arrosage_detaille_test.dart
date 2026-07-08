import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/phase_sensible_eau.dart';
import 'package:pot_a_gerer/domain/value_objects/arrosage_detaille.dart';

void main() {
  group('ArrosageDetaille — construction & accessors', () {
    test('exposes every populated aspect', () {
      final a = ArrosageDetaille(
        frequenceJoursMin: 2,
        frequenceJoursMax: 3,
        volumeLitresM2Min: 3,
        volumeLitresM2Max: 5,
        phasesSensibles: {PhaseSensibleEau.fructification},
        noteI18n: const {'fr': 'Paillez pour espacer les arrosages.'},
      );
      expect(a.aFrequence, isTrue);
      expect(a.frequenceJoursMin, 2);
      expect(a.frequenceJoursMax, 3);
      expect(a.aVolume, isTrue);
      expect(a.volumeLitresM2Min, 3);
      expect(a.volumeLitresM2Max, 5);
      expect(a.aPhasesSensibles, isTrue);
      expect(a.phasesSensibles, {PhaseSensibleEau.fructification});
      expect(a.aNote, isTrue);
    });

    test('each aspect is independently optional (phases only is valid)', () {
      final a = ArrosageDetaille(
        phasesSensibles: {PhaseSensibleEau.germination},
      );
      expect(a.aFrequence, isFalse);
      expect(a.frequenceJoursMin, isNull);
      expect(a.aVolume, isFalse);
      expect(a.volumeLitresM2Min, isNull);
      expect(a.aNote, isFalse);
      expect(a.aPhasesSensibles, isTrue);
    });

    test('note only is valid', () {
      final a = ArrosageDetaille(noteI18n: const {'fr': 'Sol frais requis.'});
      expect(a.aNote, isTrue);
      expect(a.aFrequence, isFalse);
      expect(a.aVolume, isFalse);
      expect(a.aPhasesSensibles, isFalse);
    });

    test('the returned collections are unmodifiable', () {
      final a = ArrosageDetaille(
        phasesSensibles: {PhaseSensibleEau.floraison},
        noteI18n: const {'fr': 'x'},
      );
      expect(() => a.phasesSensibles.add(PhaseSensibleEau.germination),
          throwsUnsupportedError);
    });
  });

  group('ArrosageDetaille — note localisation', () {
    test('returns the requested locale then falls back to French', () {
      final a = ArrosageDetaille(
        noteI18n: const {'fr': 'Arrosez au pied.', 'en': 'Water at the base.'},
      );
      expect(a.note('en'), 'Water at the base.');
      expect(a.note('fr'), 'Arrosez au pied.');
      expect(a.note('de'), 'Arrosez au pied.'); // fallback
    });

    test('note is null when no note carried', () {
      final a = ArrosageDetaille(phasesSensibles: {PhaseSensibleEau.floraison});
      expect(a.note('fr'), isNull);
    });
  });

  group('ArrosageDetaille — invariants', () {
    test('rejects an entirely empty detail', () {
      expect(() => ArrosageDetaille(), throwsA(isA<AssertionError>()));
    });

    test('rejects a single frequency bound', () {
      expect(() => ArrosageDetaille(frequenceJoursMin: 2),
          throwsA(isA<AssertionError>()));
      expect(() => ArrosageDetaille(frequenceJoursMax: 2),
          throwsA(isA<AssertionError>()));
    });

    test('rejects a non-positive frequency', () {
      expect(() => ArrosageDetaille(frequenceJoursMin: 0, frequenceJoursMax: 2),
          throwsA(isA<AssertionError>()));
    });

    test('rejects an inverted frequency range', () {
      expect(() => ArrosageDetaille(frequenceJoursMin: 4, frequenceJoursMax: 2),
          throwsA(isA<AssertionError>()));
    });

    test('rejects a single volume bound', () {
      expect(() => ArrosageDetaille(volumeLitresM2Min: 3),
          throwsA(isA<AssertionError>()));
    });

    test('rejects a non-positive / inverted volume range', () {
      expect(() => ArrosageDetaille(volumeLitresM2Min: 0, volumeLitresM2Max: 3),
          throwsA(isA<AssertionError>()));
      expect(() => ArrosageDetaille(volumeLitresM2Min: 5, volumeLitresM2Max: 3),
          throwsA(isA<AssertionError>()));
    });

    test('accepts equal bounds (single indicative value)', () {
      final a = ArrosageDetaille(frequenceJoursMin: 2, frequenceJoursMax: 2);
      expect(a.frequenceJoursMin, a.frequenceJoursMax);
    });
  });

  group('ArrosageDetaille — equality by value', () {
    ArrosageDetaille sample() => ArrosageDetaille(
          frequenceJoursMin: 2,
          frequenceJoursMax: 3,
          phasesSensibles: {
            PhaseSensibleEau.floraison,
            PhaseSensibleEau.fructification,
          },
          noteI18n: const {'fr': 'x'},
        );

    test('same fields are equal regardless of phase-set order', () {
      final a = ArrosageDetaille(
        phasesSensibles: {
          PhaseSensibleEau.floraison,
          PhaseSensibleEau.fructification,
        },
      );
      final b = ArrosageDetaille(
        phasesSensibles: {
          PhaseSensibleEau.fructification,
          PhaseSensibleEau.floraison,
        },
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('identical samples are equal', () {
      expect(sample(), sample());
    });

    test('a different frequency breaks equality', () {
      final other = ArrosageDetaille(
        frequenceJoursMin: 1,
        frequenceJoursMax: 3,
        phasesSensibles: {
          PhaseSensibleEau.floraison,
          PhaseSensibleEau.fructification,
        },
        noteI18n: const {'fr': 'x'},
      );
      expect(sample() == other, isFalse);
    });

    test('a different note breaks equality', () {
      final other = ArrosageDetaille(
        frequenceJoursMin: 2,
        frequenceJoursMax: 3,
        phasesSensibles: {
          PhaseSensibleEau.floraison,
          PhaseSensibleEau.fructification,
        },
        noteI18n: const {'fr': 'y'},
      );
      expect(sample() == other, isFalse);
    });
  });
}
