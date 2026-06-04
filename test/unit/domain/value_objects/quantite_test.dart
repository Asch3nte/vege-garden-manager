import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/exceptions/conversion_unite_incompatible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/quantite.dart';

void main() {
  group('Quantite — construction', () {
    test('exposes value and unit', () {
      const q = Quantite(2.5, UniteQuantite.kg);
      expect(q.valeur, 2.5);
      expect(q.unite, UniteQuantite.kg);
    });

    test('a negative quantity is rejected', () {
      expect(
        () => Quantite(-1, UniteQuantite.g),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Quantite — nature & convertibility', () {
    test('same-nature units are convertible', () {
      expect(
        const Quantite(1, UniteQuantite.kg).estConvertibleVers(UniteQuantite.g),
        isTrue,
      );
      expect(
        const Quantite(1, UniteQuantite.litre)
            .estConvertibleVers(UniteQuantite.ml),
        isTrue,
      );
    });

    test('cross-nature units are not convertible', () {
      expect(
        const Quantite(1, UniteQuantite.kg)
            .estConvertibleVers(UniteQuantite.litre),
        isFalse,
      );
      expect(
        const Quantite(1, UniteQuantite.piece)
            .estConvertibleVers(UniteQuantite.botte),
        isFalse,
      );
    });
  });

  group('Quantite — convertirVers', () {
    test('kg -> g multiplies by 1000', () {
      final r = const Quantite(2.5, UniteQuantite.kg)
          .convertirVers(UniteQuantite.g);
      expect(r.valeur, 2500);
      expect(r.unite, UniteQuantite.g);
    });

    test('g -> kg divides by 1000', () {
      final r =
          const Quantite(1500, UniteQuantite.g).convertirVers(UniteQuantite.kg);
      expect(r.valeur, 1.5);
    });

    test('litre -> ml multiplies by 1000', () {
      final r = const Quantite(1, UniteQuantite.litre)
          .convertirVers(UniteQuantite.ml);
      expect(r.valeur, 1000);
    });

    test('converting to the same unit is a no-op', () {
      final r =
          const Quantite(3, UniteQuantite.kg).convertirVers(UniteQuantite.kg);
      expect(r, const Quantite(3, UniteQuantite.kg));
    });

    test('cross-nature conversion throws a typed exception', () {
      expect(
        () => const Quantite(1, UniteQuantite.kg)
            .convertirVers(UniteQuantite.litre),
        throwsA(isA<ConversionUniteIncompatibleException>()),
      );
      expect(
        () => const Quantite(1, UniteQuantite.piece)
            .convertirVers(UniteQuantite.botte),
        throwsA(isA<ConversionUniteIncompatibleException>()),
      );
    });

    test('the exception carries the source and target units', () {
      try {
        const Quantite(1, UniteQuantite.kg).convertirVers(UniteQuantite.ml);
        fail('expected an exception');
      } on ConversionUniteIncompatibleException catch (e) {
        expect(e.source, UniteQuantite.kg);
        expect(e.cible, UniteQuantite.ml);
      }
    });
  });

  group('Quantite — arithmetic', () {
    test('addition converts the operand to this unit', () {
      final r = const Quantite(1, UniteQuantite.kg) +
          const Quantite(500, UniteQuantite.g);
      expect(r, const Quantite(1.5, UniteQuantite.kg));
      expect(r.unite, UniteQuantite.kg);
    });

    test('subtraction converts the operand to this unit', () {
      final r = const Quantite(1, UniteQuantite.kg) -
          const Quantite(200, UniteQuantite.g);
      expect(r, const Quantite(0.8, UniteQuantite.kg));
    });

    test('subtracting more than available violates the non-negative invariant',
        () {
      expect(
        () => const Quantite(200, UniteQuantite.g) -
            const Quantite(1, UniteQuantite.kg),
        throwsA(isA<AssertionError>()),
      );
    });

    test('cross-nature addition throws a typed exception', () {
      expect(
        () => const Quantite(1, UniteQuantite.kg) +
            const Quantite(1, UniteQuantite.litre),
        throwsA(isA<ConversionUniteIncompatibleException>()),
      );
    });
  });

  group('Quantite — semantic equality', () {
    test('same amount in different units of the same nature is equal', () {
      expect(
        const Quantite(1, UniteQuantite.kg),
        const Quantite(1000, UniteQuantite.g),
      );
    });

    test('equal quantities share a hashCode', () {
      expect(
        const Quantite(1, UniteQuantite.kg).hashCode,
        const Quantite(1000, UniteQuantite.g).hashCode,
      );
    });

    test('same value but different natures are not equal', () {
      expect(
        const Quantite(1, UniteQuantite.g) ==
            const Quantite(1, UniteQuantite.ml),
        isFalse,
      );
      expect(
        const Quantite(1, UniteQuantite.piece) ==
            const Quantite(1, UniteQuantite.botte),
        isFalse,
      );
    });

    test('different amounts are not equal', () {
      expect(
        const Quantite(1, UniteQuantite.kg) ==
            const Quantite(2, UniteQuantite.kg),
        isFalse,
      );
    });
  });
}
