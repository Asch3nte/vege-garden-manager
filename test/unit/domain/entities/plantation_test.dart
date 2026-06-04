import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/recolte.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/exceptions/conversion_unite_incompatible_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/quantite.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

Plantation _plantation({
  String id = 'pl1',
  int nombrePieds = 3,
  Surface? surface,
}) =>
    Plantation(
      id: id,
      planteId: 'tomate',
      parcelleId: 'par1',
      dateMiseEnPlace: DateTime(2026, 5, 1),
      methode: MethodeMiseEnPlace.repiquage,
      surfaceOccupee: surface ?? Surface.enMetresCarres(1.8),
      nombrePieds: nombrePieds,
    );

Recolte _recolte(String id, Quantite q, {String plantationId = 'pl1'}) =>
    Recolte(
      id: id,
      plantationId: plantationId,
      date: DateTime(2026, 7, 20),
      quantite: q,
    );

void main() {
  group('Plantation — construction & invariants', () {
    test('is active with no harvests by default', () {
      final p = _plantation();
      expect(p.estActive(), isTrue);
      expect(p.statut, StatutPlantation.enCours);
      expect(p.dateFinReelle, isNull);
      expect(p.recoltes, isEmpty);
    });

    test('rejects empty id, non-positive pieds and zero surface', () {
      expect(() => _plantation(id: ''), throwsA(isA<AssertionError>()));
      expect(() => _plantation(nombrePieds: 0), throwsA(isA<AssertionError>()));
      expect(
        () => _plantation(surface: Surface.zero),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects enCours with an end date (cross-field invariant)', () {
      expect(
        () => Plantation(
          id: 'x',
          planteId: 'tomate',
          parcelleId: 'par1',
          dateMiseEnPlace: DateTime(2026, 5, 1),
          methode: MethodeMiseEnPlace.semisDirect,
          surfaceOccupee: Surface.enMetresCarres(1),
          nombrePieds: 1,
          dateFinReelle: DateTime(2026, 9, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Plantation — age', () {
    test('ageDepuis measures from the planting date', () {
      final p = _plantation();
      expect(p.ageDepuis(DateTime(2026, 5, 31)).inDays, 30);
    });
  });

  group('Plantation — harvests', () {
    test('records harvests and exposes them unmodifiably', () {
      final p = _plantation();
      p.enregistrerRecolte(_recolte('r1', const Quantite(1, UniteQuantite.kg)));
      expect(p.recoltes, hasLength(1));
      expect(
        () => p.recoltes.add(_recolte('r2', const Quantite(1, UniteQuantite.kg))),
        throwsUnsupportedError,
      );
    });

    test('rejects a harvest that references another plantation', () {
      final p = _plantation();
      expect(
        () => p.enregistrerRecolte(
          _recolte('r1', const Quantite(1, UniteQuantite.kg),
              plantationId: 'other'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('total is null when nothing was harvested', () {
      expect(_plantation().quantiteTotaleRecoltee(), isNull);
    });

    test('total sums same-nature harvests (2 kg + 500 g = 2.5 kg)', () {
      final p = _plantation();
      p.enregistrerRecolte(_recolte('r1', const Quantite(2, UniteQuantite.kg)));
      p.enregistrerRecolte(_recolte('r2', const Quantite(500, UniteQuantite.g)));
      expect(p.quantiteTotaleRecoltee(), const Quantite(2.5, UniteQuantite.kg));
    });

    test('total throws when harvests mix incompatible natures', () {
      final p = _plantation();
      p.enregistrerRecolte(_recolte('r1', const Quantite(1, UniteQuantite.kg)));
      p.enregistrerRecolte(
          _recolte('r2', const Quantite(3, UniteQuantite.piece)));
      expect(
        p.quantiteTotaleRecoltee,
        throwsA(isA<ConversionUniteIncompatibleException>()),
      );
    });
  });

  group('Plantation — status transitions', () {
    test('moving to a terminal status sets the end date and reason', () {
      final p = _plantation();
      p.changerStatut(
        StatutPlantation.recoltee,
        dateFin: DateTime(2026, 9, 1),
        raison: 'fin de saison',
      );
      expect(p.estActive(), isFalse);
      expect(p.statut, StatutPlantation.recoltee);
      expect(p.dateFinReelle, DateTime(2026, 9, 1));
      expect(p.raisonFin, 'fin de saison');
    });

    test('a terminal status requires an end date', () {
      final p = _plantation();
      expect(
        () => p.changerStatut(StatutPlantation.echouee),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the end date cannot precede the planting date', () {
      final p = _plantation();
      expect(
        () => p.changerStatut(
          StatutPlantation.arrachee,
          dateFin: DateTime(2026, 4, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('moving back to enCours clears the end date and reason', () {
      final p = _plantation();
      p.changerStatut(StatutPlantation.recoltee, dateFin: DateTime(2026, 9, 1));
      p.changerStatut(StatutPlantation.enCours);
      expect(p.estActive(), isTrue);
      expect(p.dateFinReelle, isNull);
      expect(p.raisonFin, isNull);
    });
  });

  group('Plantation — identity', () {
    test('equality is by id', () {
      expect(_plantation(id: 'a') == _plantation(id: 'a'), isTrue);
      expect(_plantation(id: 'a') == _plantation(id: 'b'), isFalse);
    });
  });
}
