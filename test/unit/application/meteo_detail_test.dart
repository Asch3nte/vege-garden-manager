// Unit tests for the hourly weather provider.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/application/state/meteo_detail_notifier.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_horaire.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _FakeLoc extends Fake implements Localisation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLoc()));

  late MockPotagers potagers;
  late MockMeteo meteo;
  late MockPreferences preferences;

  setUp(() {
    potagers = MockPotagers();
    meteo = MockMeteo();
    preferences = MockPreferences();
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
  });

  Potager unPotager({Localisation? localisation}) => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
        localisation: localisation ?? const Localisation.nonDefinie(),
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(potagers),
      meteoServiceProvider.overrideWithValue(meteo),
      preferencesRepositoryProvider.overrideWithValue(preferences),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('no position → empty list, no weather call', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());

    final heures = await conteneur().read(meteoHoraireProvider.future);

    expect(heures, isEmpty);
    verifyNever(() => meteo.obtenirPrevisionsHoraires(any(),
        nbJours: any(named: 'nbJours')));
  });

  test('with a position → returns the service hourly forecast', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => unPotager(
        localisation: Localisation.gps(latitude: 48.85, longitude: 2.35),
      ),
    );
    when(() => meteo.obtenirPrevisionsHoraires(any(),
            nbJours: any(named: 'nbJours')))
        .thenAnswer((_) async => [
              PrevisionHoraire(
                heure: DateTime(2026, 6, 9, 8),
                temperature: 21,
                precipitationsMm: 0,
              ),
            ]);

    final heures = await conteneur().read(meteoHoraireProvider.future);

    expect(heures, hasLength(1));
    expect(heures.single.temperature, 21);
  });
}
