import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/application/state/notifications_notifier.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_alerte_meteo.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Localisation.nonDefinie());
  });

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockPreferences preferences;
  late MockMeteo meteo;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    preferences = MockPreferences();
    meteo = MockMeteo();
  });

  final position = Localisation.gps(latitude: 48.85, longitude: 2.35);

  Potager unPotagerPositionne() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
        localisation: position,
      );

  Parcelle uneParcelle(String id) => Parcelle(
        id: id,
        nom: 'Carré',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.pleinSoleil,
      );

  Plantation unePlantation(
    String id, {
    StatutPlantation statut = StatutPlantation.enCours,
  }) =>
      Plantation(
        id: id,
        planteId: 'tomate',
        parcelleId: 'z-1',
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.repiquage,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 2,
        statut: statut,
        // Terminal statuses carry an end date (domain invariant).
        dateFinReelle:
            statut == StatutPlantation.enCours ? null : DateTime(2026, 6, 1),
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      preferencesRepositoryProvider.overrideWithValue(preferences),
      potagerRepositoryProvider.overrideWithValue(potagers),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      plantationRepositoryProvider.overrideWithValue(plantations),
      meteoServiceProvider.overrideWithValue(meteo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('auto weather-fetch off → empty, no forecast fetched (opt-out)',
      () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur(meteoAutoActive: false));

    final alertes = await conteneur().read(alertesMeteoProvider.future);

    expect(alertes, isEmpty);
    verifyNever(() => meteo.obtenirPrevisions(any(), any()));
    // Short-circuits before touching the garden at all.
    verifyNever(() => potagers.obtenirPotagerActif());
  });

  test('no active garden → empty', () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);

    final alertes = await conteneur().read(alertesMeteoProvider.future);

    expect(alertes, isEmpty);
    verifyNever(() => meteo.obtenirPrevisions(any(), any()));
  });

  test('positioned garden with an in-place culture → frost alert listing it',
      () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotagerPositionne());
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1')]);
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('pl-1')]);
    when(() => meteo.obtenirPrevisions(position, any())).thenAnswer(
      (_) async => [
        PrevisionMeteo(
          date: DateTime.utc(2026, 1, 12),
          tempMin: -2,
          tempMax: 4,
          precipitationsMm: 0,
        ),
      ],
    );

    final alertes = await conteneur().read(alertesMeteoProvider.future);

    expect(alertes, hasLength(1));
    expect(alertes.single.type, TypeAlerteMeteo.gel);
    expect(alertes.single.plantationsConcernees, ['pl-1']);
  });

  test('terminal plantations are excluded → no in-place culture → empty',
      () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotagerPositionne());
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1')]);
    when(() => plantations.obtenirParParcelle('z-1')).thenAnswer(
      (_) async => [unePlantation('pl-1', statut: StatutPlantation.recoltee)],
    );

    final alertes = await conteneur().read(alertesMeteoProvider.future);

    expect(alertes, isEmpty);
    // No in-place culture → the use case never fetches the forecast.
    verifyNever(() => meteo.obtenirPrevisions(any(), any()));
  });
}
