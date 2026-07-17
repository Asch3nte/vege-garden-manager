// Unit tests for the home weather-card view-model and its watering verdict.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_notifier.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_vue.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/donnees_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _FakeLoc extends Fake implements Localisation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLoc()));

  late MockPotagers potagers;
  late MockMeteo meteo;
  late MockPreferences prefs;

  setUp(() {
    potagers = MockPotagers();
    meteo = MockMeteo();
    prefs = MockPreferences();
    // Default: auto weather-fetch on (the opt-out being off is a dedicated test).
    when(() => prefs.charger())
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

  DonneesMeteo jour({
    double tempMax = 20,
    double precip = 0,
    bool canicule = false,
    bool gel = false,
  }) =>
      DonneesMeteo(
        date: DateTime(2026, 6, 10),
        tempMin: 12,
        tempMax: tempMax,
        tempMoyenne: (12 + tempMax) / 2,
        precipitationsMm: precip,
        ventVitesseMax: 10,
        risqueCanicule: canicule,
        risqueGel: gel,
      );

  PrevisionMeteo prev(double precip, {double proba = 0}) => PrevisionMeteo(
        date: DateTime(2026, 6, 11),
        tempMin: 12,
        tempMax: 22,
        precipitationsMm: precip,
        probabilitePluie: proba,
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(potagers),
      meteoServiceProvider.overrideWithValue(meteo),
      preferencesRepositoryProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('no usable position → weather unavailable', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());

    final vue = await conteneur().read(meteoAccueilProvider.future);

    expect(vue.disponible, isFalse);
    verifyNever(() => meteo.obtenirMeteoActuelle(any()));
  });

  test('auto weather-fetch off → muted, no fetch (opt-out)', () async {
    when(() => prefs.charger()).thenAnswer(
        (_) async => PreferencesUtilisateur(meteoAutoActive: false));

    final vue = await conteneur().read(meteoAccueilProvider.future);

    expect(vue.meteoDesactivee, isTrue);
    expect(vue.disponible, isFalse);
    // No automatic Open-Meteo call, and the position is not even queried.
    verifyNever(() => meteo.obtenirMeteoActuelle(any()));
    verifyNever(() => potagers.obtenirPotagerActif());
  });

  test('rain in the forecast → "rain coming" verdict', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => unPotager(
        localisation: Localisation.gps(latitude: 48.85, longitude: 2.35),
      ),
    );
    when(() => meteo.obtenirMeteoActuelle(any()))
        .thenAnswer((_) async => jour(tempMax: 22));
    when(() => meteo.obtenirPrevisions(any(), any()))
        .thenAnswer((_) async => [prev(12, proba: 0.6)]); // 12 * 0.6 = 7.2 ≥ seuilScorePluie (6.0) → rain coming

    final vue = await conteneur().read(meteoAccueilProvider.future);

    expect(vue.disponible, isTrue);
    expect(vue.verdict, VerdictMeteo.pluieAVenir);
    expect(vue.tempMax, 22);
  });

  test('hot and dry → "water advised" verdict', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => unPotager(
        localisation: Localisation.gps(latitude: 48.85, longitude: 2.35),
      ),
    );
    when(() => meteo.obtenirMeteoActuelle(any()))
        .thenAnswer((_) async => jour(tempMax: 31));
    when(() => meteo.obtenirPrevisions(any(), any()))
        .thenAnswer((_) async => [prev(0)]);

    final vue = await conteneur().read(meteoAccueilProvider.future);

    expect(vue.verdict, VerdictMeteo.arroserConseille);
  });

  test('recent rain → "moist soil" verdict', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => unPotager(
        localisation: Localisation.gps(latitude: 48.85, longitude: 2.35),
      ),
    );
    when(() => meteo.obtenirMeteoActuelle(any()))
        .thenAnswer((_) async => jour(tempMax: 20, precip: 18)); // >= 15 mm
    when(() => meteo.obtenirPrevisions(any(), any()))
        .thenAnswer((_) async => [prev(0)]);

    final vue = await conteneur().read(meteoAccueilProvider.future);

    expect(vue.verdict, VerdictMeteo.solHumide);
  });
}
