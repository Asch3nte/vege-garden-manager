// Unit tests for the rich weather detail view-model provider.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/application/state/meteo_detail_notifier.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_geocodage_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/donnees_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_horaire.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

class MockGeocodage extends Mock implements AbstractGeocodageService {}

class _FakeLoc extends Fake implements Localisation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLoc()));

  late MockPotagers potagers;
  late MockMeteo meteo;
  late MockGeocodage geocodage;

  setUp(() {
    potagers = MockPotagers();
    meteo = MockMeteo();
    geocodage = MockGeocodage();
  });

  final loc = Localisation.gps(latitude: 50.85, longitude: 4.35);

  Potager unPotager({Localisation? localisation}) => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
        localisation: localisation ?? const Localisation.nonDefinie(),
      );

  DonneesMeteo unesDonnees({double precipitationsMm = 0}) => DonneesMeteo(
        date: DateTime(2026, 6, 18),
        tempMin: 15,
        tempMax: 26,
        tempMoyenne: 20,
        precipitationsMm: precipitationsMm,
        ventVitesseMax: 10,
      );

  PrevisionMeteo unePrevision({int offsetJours = 0, double precipMm = 0, double probaP = 0}) =>
      PrevisionMeteo(
        date: DateTime(2026, 6, 18).add(Duration(days: offsetJours)),
        tempMin: 15,
        tempMax: 25,
        precipitationsMm: precipMm,
        probabilitePluie: probaP,
      );

  PrevisionHoraire uneHeure({int heure = 8}) => PrevisionHoraire(
        heure: DateTime(2026, 6, 18, heure),
        temperature: 20,
        precipitationsMm: 0,
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(potagers),
      meteoServiceProvider.overrideWithValue(meteo),
      geocodageServiceProvider.overrideWithValue(geocodage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  void stubAllServices({
    String? nomVille = 'Bruxelles',
    double? elevation = 65.0,
    double precipActuelle = 0,
    List<PrevisionMeteo>? previsions,
    List<PrevisionHoraire>? horaires,
  }) {
    when(() => geocodage.obtenirNomLocalite(any()))
        .thenAnswer((_) async => nomVille);
    when(() => meteo.obtenirElevation(any()))
        .thenAnswer((_) async => elevation);
    when(() => meteo.obtenirMeteoActuelle(any()))
        .thenAnswer((_) async => unesDonnees(precipitationsMm: precipActuelle));
    when(() => meteo.obtenirPrevisions(any(), any()))
        .thenAnswer((_) async => previsions ?? [unePrevision(), unePrevision(offsetJours: 1)]);
    when(() => meteo.obtenirPrevisionsHoraires(any(), nbJours: any(named: 'nbJours')))
        .thenAnswer((_) async => horaires ?? [uneHeure(heure: 8), uneHeure(heure: 12)]);
  }

  // ── No position ─────────────────────────────────────────────────────────

  test('no active garden → indisponible, no weather call', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.disponible, isFalse);
    verifyNever(() => meteo.obtenirMeteoActuelle(any()));
  });

  test('garden with no position → indisponible, no weather call', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.disponible, isFalse);
    expect(vue.nomPotager, 'Mon potager');
    verifyNever(() => meteo.obtenirMeteoActuelle(any()));
  });

  // ── Happy path ──────────────────────────────────────────────────────────

  test('with position → disponible with garden name and station', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices();

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.disponible, isTrue);
    expect(vue.nomPotager, 'Mon potager');
    expect(vue.nomStation, 'Bruxelles');
    expect(vue.elevation, 65.0);
  });

  test('jours count matches previsions list', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices(
      previsions: [
        unePrevision(),
        unePrevision(offsetJours: 1),
        unePrevision(offsetJours: 2),
      ],
    );

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.jours, hasLength(3));
  });

  test('hourly data is grouped into the matching day', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices(
      previsions: [unePrevision(), unePrevision(offsetJours: 1)],
      horaires: [
        uneHeure(heure: 8),
        uneHeure(heure: 14),
        PrevisionHoraire(
          heure: DateTime(2026, 6, 19, 10),
          temperature: 22,
          precipitationsMm: 0,
        ),
      ],
    );

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.jours[0].heures, hasLength(2));
    expect(vue.jours[1].heures, hasLength(1));
  });

  test('resumeAujourdhui is non-empty', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices();

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.resumeAujourdhui, isNotEmpty);
  });

  test('resumeDemain is non-null when J+1 data exists', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices();

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.resumeDemain, isNotNull);
  });

  test('resumeDemain is null when only one day of previsions', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices(previsions: [unePrevision()]);

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.resumeDemain, isNull);
  });

  test('explicationTaches is non-empty', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices();

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.explicationTaches, isNotEmpty);
  });

  // ── Verdict derivation ──────────────────────────────────────────────────

  test('verdict is pluieAVenir when prevision score above threshold', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    // precipMm * probabilite = 20 * 0.9 = 18, above BilanArrosage.seuilScorePluie (5).
    stubAllServices(
      previsions: [unePrevision(precipMm: 20, probaP: 0.9)],
    );

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.verdictArrosage.name, 'pluieAVenir');
  });

  // ── Nominatim fallback ──────────────────────────────────────────────────

  test('nomStation is null when Nominatim returns null', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices(nomVille: null);

    final vue = await conteneur().read(meteoDetailProvider.future);

    expect(vue.disponible, isTrue);
    expect(vue.nomStation, isNull);
  });

  // ── All five services called ────────────────────────────────────────────

  test('all five parallel services are invoked once', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager(localisation: loc));
    stubAllServices();

    await conteneur().read(meteoDetailProvider.future);

    verify(() => geocodage.obtenirNomLocalite(any())).called(1);
    verify(() => meteo.obtenirElevation(any())).called(1);
    verify(() => meteo.obtenirMeteoActuelle(any())).called(1);
    verify(() => meteo.obtenirPrevisions(any(), any())).called(1);
    verify(() => meteo.obtenirPrevisionsHoraires(any(), nbJours: any(named: 'nbJours')))
        .called(1);
  });
}
