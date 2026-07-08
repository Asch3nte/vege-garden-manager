import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/phase_sensible_eau.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/value_objects/arrosage_detaille.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';

BesoinsCulture _tomate({Set<QualiteSol>? sol}) => BesoinsCulture(
      eau: BesoinEau.eleve,
      soleil: NiveauSoleil.pleinSoleil,
      phMin: 6.0,
      phMax: 7.0,
      qualitesSol: sol ?? {QualiteSol.riche, QualiteSol.bienDraine},
    );

void main() {
  group('BesoinsCulture — construction & accessors', () {
    test('exposes its fields', () {
      final b = _tomate();
      expect(b.eau, BesoinEau.eleve);
      expect(b.soleil, NiveauSoleil.pleinSoleil);
      expect(b.phMin, 6.0);
      expect(b.phMax, 7.0);
      expect(b.qualitesSol, {QualiteSol.riche, QualiteSol.bienDraine});
    });

    test('qualitesSol defaults to empty', () {
      final b = BesoinsCulture(
        eau: BesoinEau.faible,
        soleil: NiveauSoleil.miOmbre,
        phMin: 5.5,
        phMax: 7.5,
      );
      expect(b.qualitesSol, isEmpty);
    });

    test('the returned set is unmodifiable', () {
      final b = _tomate();
      expect(() => b.qualitesSol.add(QualiteSol.sec), throwsUnsupportedError);
    });
  });

  group('BesoinsCulture — pH invariants', () {
    test('rejects pH out of 0..14', () {
      expect(
        () => BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: -1,
          phMax: 7,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 15,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects phMin greater than phMax', () {
      expect(
        () => BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 7.5,
          phMax: 6.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('acceptePh respects the inclusive window', () {
      final b = _tomate(); // 6.0 .. 7.0
      expect(b.acceptePh(6.0), isTrue);
      expect(b.acceptePh(7.0), isTrue);
      expect(b.acceptePh(6.5), isTrue);
      expect(b.acceptePh(5.9), isFalse);
      expect(b.acceptePh(7.1), isFalse);
    });
  });

  group('BesoinsCulture — equality by value', () {
    test('same fields are equal regardless of soil-set order', () {
      final a = _tomate(sol: {QualiteSol.riche, QualiteSol.bienDraine});
      final b = _tomate(sol: {QualiteSol.bienDraine, QualiteSol.riche});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different soil sets are not equal', () {
      expect(
        _tomate(sol: {QualiteSol.riche}) == _tomate(sol: {QualiteSol.pauvre}),
        isFalse,
      );
    });

    test('different pH window is not equal', () {
      final a = _tomate();
      final b = BesoinsCulture(
        eau: BesoinEau.eleve,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6.0,
        phMax: 7.5,
        qualitesSol: {QualiteSol.riche, QualiteSol.bienDraine},
      );
      expect(a == b, isFalse);
    });
  });

  group('BesoinsCulture — detailed watering (optional)', () {
    test('arrosageDetaille is null by default', () {
      final b = _tomate();
      expect(b.arrosageDetaille, isNull);
      expect(b.aArrosageDetaille, isFalse);
    });

    test('carries the detail when provided', () {
      final detail = ArrosageDetaille(
        frequenceJoursMin: 2,
        frequenceJoursMax: 3,
        phasesSensibles: {PhaseSensibleEau.fructification},
      );
      final b = BesoinsCulture(
        eau: BesoinEau.eleve,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6.0,
        phMax: 7.0,
        arrosageDetaille: detail,
      );
      expect(b.aArrosageDetaille, isTrue);
      expect(b.arrosageDetaille, detail);
    });

    test('differing detail breaks equality', () {
      BesoinsCulture avec(ArrosageDetaille? d) => BesoinsCulture(
            eau: BesoinEau.eleve,
            soleil: NiveauSoleil.pleinSoleil,
            phMin: 6.0,
            phMax: 7.0,
            arrosageDetaille: d,
          );
      final a = avec(ArrosageDetaille(frequenceJoursMin: 2, frequenceJoursMax: 3));
      final b = avec(ArrosageDetaille(frequenceJoursMin: 1, frequenceJoursMax: 3));
      final none = avec(null);
      expect(a == b, isFalse);
      expect(a == none, isFalse);
      expect(a == avec(ArrosageDetaille(frequenceJoursMin: 2, frequenceJoursMax: 3)),
          isTrue);
    });
  });
}
