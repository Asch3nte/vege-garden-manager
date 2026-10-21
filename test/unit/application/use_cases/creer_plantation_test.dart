import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/creer_plantation.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/exceptions/surface_insuffisante_exception.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

class _MockPlantations extends Mock implements AbstractPlantationRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakePlantation extends Fake implements Plantation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePlantation()));

  late _MockPlantations plantations;
  late _MockParcelles parcelles;
  late CreerPlantation useCase;

  Plantation enPlace(double m2) => Plantation(
        id: 'existante',
        planteId: 'tomate',
        parcelleId: 'z1',
        dateMiseEnPlace: DateTime(2026, 5, 1),
        methode: MethodeMiseEnPlace.repiquage,
        surfaceOccupee: Surface.enMetresCarres(m2),
        nombrePieds: 1,
      );

  setUp(() {
    plantations = _MockPlantations();
    parcelles = _MockParcelles();
    useCase = CreerPlantation(plantations, parcelles, genererId: () => 'p1');
    when(() => parcelles.obtenirParId('z1')).thenAnswer((_) async => Parcelle(
          id: 'z1',
          nom: 'Bac',
          potagerId: 'pot1',
          type: TypeParcelle.bacSureleve,
          surface: Surface.enMetresCarres(2),
          exposition: NiveauSoleil.pleinSoleil,
        ));
    when(() => plantations.obtenirParParcelle('z1'))
        .thenAnswer((_) async => [enPlace(1.5)]);
    when(() => plantations.sauvegarder(any())).thenAnswer((_) async {});
  });

  Future<Plantation> creer(double m2) => useCase.executer(
        planteId: 'basilic',
        parcelleId: 'z1',
        dateMiseEnPlace: DateTime(2026, 6, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(m2),
        nombrePieds: 1,
      );

  test('saves a plantation that fits in the free surface', () async {
    final p = await creer(0.5);

    expect(p.id, 'p1');
    verify(() => plantations.sauvegarder(p)).called(1);
  });

  test('refuses a plantation that does not fit, without saving', () async {
    await expectLater(creer(1), throwsA(isA<SurfaceInsuffisanteException>()));
    verifyNever(() => plantations.sauvegarder(any()));
  });
}
