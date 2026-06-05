import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/engine/evaluateur_alertes_meteo.dart';
import 'package:pot_a_gerer/application/use_cases/detecter_alertes_meteo.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/type_alerte_meteo.dart';
import 'package:pot_a_gerer/domain/exceptions/meteo_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

class MockMeteoService extends Mock implements AbstractMeteoService {}

void main() {
  final loc =
      Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);

  Plantation plantation(String id) => Plantation(
        id: id,
        planteId: 'tomate',
        parcelleId: 'par1',
        dateMiseEnPlace: DateTime.utc(2026, 5, 1),
        methode: MethodeMiseEnPlace.repiquage,
        surfaceOccupee: Surface.enMetresCarres(1),
        nombrePieds: 2,
      );

  late MockMeteoService meteo;
  late DetecterAlertesMeteo useCase;

  setUp(() {
    meteo = MockMeteoService();
    useCase = DetecterAlertesMeteo(meteo, const EvaluateurAlertesMeteo());
  });

  test('raises a generic alert listing every in-place plantation', () async {
    when(() => meteo.obtenirPrevisions(loc, 3)).thenAnswer((_) async => [
          PrevisionMeteo(
            date: DateTime.utc(2026, 1, 12),
            tempMin: -2,
            tempMax: 4,
            precipitationsMm: 0,
          ),
        ]);

    final alertes = await useCase.executer(
      localisation: loc,
      plantationsActives: [plantation('pl1'), plantation('pl2')],
    );

    expect(alertes, hasLength(1));
    expect(alertes.single.type, TypeAlerteMeteo.gel);
    expect(alertes.single.plantationsConcernees, ['pl1', 'pl2']);
  });

  test('returns nothing when the location is undefined (no weather)', () async {
    final alertes = await useCase.executer(
      localisation: const Localisation.nonDefinie(),
      plantationsActives: [plantation('pl1')],
    );
    expect(alertes, isEmpty);
    verifyNever(
        () => meteo.obtenirPrevisions(const Localisation.nonDefinie(), any()));
  });

  test('returns nothing when no culture is in place', () async {
    final alertes = await useCase.executer(
      localisation: loc,
      plantationsActives: const [],
    );
    expect(alertes, isEmpty);
    verifyNever(() => meteo.obtenirPrevisions(loc, any()));
  });

  test('degrades gracefully when the weather is unavailable offline', () async {
    when(() => meteo.obtenirPrevisions(loc, 3))
        .thenThrow(MeteoIndisponibleException('offline'));

    final alertes = await useCase.executer(
      localisation: loc,
      plantationsActives: [plantation('pl1')],
    );
    expect(alertes, isEmpty);
  });
}
