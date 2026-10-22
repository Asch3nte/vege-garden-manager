import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/modifier_parcelle.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/exceptions/surface_insuffisante_exception.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockPlantations extends Mock implements AbstractPlantationRepository {}

class _FakeParcelle extends Fake implements Parcelle {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeParcelle()));

  late _MockParcelles parcelles;
  late _MockPlantations plantations;
  late ModifierParcelle useCase;

  Parcelle zone(double m2) => Parcelle(
    id: 'par1',
    nom: 'Planche',
    potagerId: 'pot1',
    type: TypeParcelle.pleineTerre,
    surface: Surface.enMetresCarres(m2),
    exposition: NiveauSoleil.pleinSoleil,
  );

  Plantation plantation(double m2) => Plantation(
    id: 'pl1',
    planteId: 'tomate',
    parcelleId: 'par1',
    dateMiseEnPlace: DateTime(2026, 5, 1),
    methode: MethodeMiseEnPlace.repiquage,
    surfaceOccupee: Surface.enMetresCarres(m2),
    nombrePieds: 2,
    statut: StatutPlantation.enCours,
  );

  setUp(() {
    parcelles = _MockParcelles();
    plantations = _MockPlantations();
    useCase = ModifierParcelle(parcelles, plantations);
    when(() => parcelles.sauvegarder(any())).thenAnswer((_) async {});
    when(() => plantations.obtenirParParcelle('par1'))
        .thenAnswer((_) async => [plantation(2)]);
    when(() => parcelles.obtenirParId('par1')).thenAnswer((_) async => zone(3));
  });

  test('saves a zone that still holds its plantations', () async {
    final modifiee = zone(2);
    await useCase.executer(modifiee);
    verify(() => parcelles.sauvegarder(modifiee)).called(1);
  });

  test('an unchanged surface is saved even when already overfull', () async {
    when(() => parcelles.obtenirParId('par1'))
        .thenAnswer((_) async => zone(1.5));
    final renommee = zone(1.5)..renommer('Planche sud');
    await useCase.executer(renommee);
    verify(() => parcelles.sauvegarder(renommee)).called(1);
    verifyNever(() => plantations.obtenirParParcelle(any()));
  });

  test('refuses a surface below the one its plantations take up', () async {
    await expectLater(useCase.executer(zone(1.5)),
        throwsA(isA<SurfaceInsuffisanteException>()));
    verifyNever(() => parcelles.sauvegarder(any()));
  });
}
