import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/accueil_notifier.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/entities/recolte.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_recolte_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/quantite.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockRecoltes extends Mock implements AbstractRecolteRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

/// No-op stub: watering task generation is tested separately.
class _StubGenererTachesArrosage implements GenererTachesArrosage {
  @override
  Future<void> executer() async {}
}

class _FakeTache extends Fake implements Tache {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  // Pinned "now" so the today-window is deterministic.
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockTaches taches;
  late MockPreferences preferences;
  late MockPlantations plantations;
  late MockRecoltes recoltes;
  late MockMeteo meteo;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    taches = MockTaches();
    preferences = MockPreferences();
    plantations = MockPlantations();
    recoltes = MockRecoltes();
    meteo = MockMeteo();
    when(() => plantations.obtenirParParcelle(any())).thenAnswer((_) async => []);
    when(() => recoltes.obtenirParPlantation(any())).thenAnswer((_) async => []);
  });

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      );

  Parcelle uneParcelle(String id, String nom) => Parcelle(
        id: id,
        nom: nom,
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.pleinSoleil,
      );

  Tache uneTache(String id, String titre, EtatTache etat, DateTime quand,
          {TypeTache type = TypeTache.arrosage}) =>
      Tache(
        id: id,
        titre: titre,
        type: type,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: quand,
        etat: etat,
        // A completed task must carry a completion date (domain invariant).
        dateRealisation: etat == EtatTache.terminee ? quand : null,
      );

  Plantation unePlantation(String id, String parcelleId) => Plantation(
        id: id,
        planteId: 'tomate',
        parcelleId: parcelleId,
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 3,
      );

  Recolte uneRecolte(String id, String plantationId, DateTime date) => Recolte(
        id: id,
        plantationId: plantationId,
        date: date,
        quantite: const Quantite(1, UniteQuantite.kg),
      );

  /// Container with every repository the dashboard reads + the clock.
  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(potagers),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      tacheRepositoryProvider.overrideWithValue(taches),
      preferencesRepositoryProvider.overrideWithValue(preferences),
      plantationRepositoryProvider.overrideWithValue(plantations),
      recolteRepositoryProvider.overrideWithValue(recoltes),
      meteoServiceProvider.overrideWithValue(meteo),
      horlogeProvider.overrideWithValue(() => maintenant),
      genererTachesArrosageProvider
          .overrideWith((ref) async => _StubGenererTachesArrosage()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('assembles garden name, zones, level and today\'s tasks', () async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(
        niveauExperience: NiveauExperience.intermediaire,
      ),
    );
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [uneParcelle('z-1', 'Carré nord'), uneParcelle('z-2', 'Serre')],
    );
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [uneTache('t-1', 'Arroser', EtatTache.aFaire, maintenant)],
    );

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.nomPotager, 'Mon potager');
    expect(vue.niveau, NiveauExperience.intermediaire);
    expect(vue.zones.map((z) => z.nom), ['Carré nord', 'Serre']);
    expect(vue.nombreZones, 2);
    expect(vue.tachesDuJour, hasLength(1));
    expect(vue.nombreTachesAFaire, 1);
  });

  test('queries the task repo with today\'s [midnight, next midnight) window',
      () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    await conteneur().read(accueilProvider.future);

    final captured =
        verify(() => taches.obtenirEntreDates(captureAny(), captureAny()))
            .captured;
    expect(captured[0], DateTime(2026, 6, 9));
    expect(captured[1], DateTime(2026, 6, 10));
  });

  test('orders tasks: undone before done, then by planned time', () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('done', 'Fait', EtatTache.terminee, maintenant),
        uneTache('late', 'Tard', EtatTache.aFaire, DateTime(2026, 6, 9, 18)),
        uneTache('early', 'Tôt', EtatTache.aFaire, DateTime(2026, 6, 9, 7)),
      ],
    );

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.tachesDuJour.map((t) => t.id), ['early', 'late', 'done']);
  });

  test('season statistics are visible only at expert level', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    for (final (niveau, attendu) in [
      (NiveauExperience.debutant, false),
      (NiveauExperience.intermediaire, false),
      (NiveauExperience.expert, true),
    ]) {
      when(() => preferences.charger()).thenAnswer(
        (_) async => PreferencesUtilisateur(niveauExperience: niveau),
      );
      final vue = await conteneur().read(accueilProvider.future);
      expect(vue.statistiquesVisibles, attendu, reason: niveau.name);
    }
  });

  test('counts this year\'s harvests; no alerts without a position', () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager()); // no position
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1', 'Carré nord')]);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('p-1', 'z-1')]);
    when(() => recoltes.obtenirParPlantation('p-1')).thenAnswer(
      (_) async => [
        uneRecolte('r-1', 'p-1', DateTime(2026, 5, 20)), // this year
        uneRecolte('r-2', 'p-1', DateTime(2025, 8, 10)), // last year (excluded)
      ],
    );

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.nombreRecoltesSaison, 1);
    expect(vue.nombreAlertes, 0); // garden has no position → no alerts
  });

  test('no active garden → empty overview, null name', () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.nomPotager, isNull);
    expect(vue.zones, isEmpty);
    expect(vue.potagerVide, isTrue);
    // The parcelle repo is never queried without an active garden.
    verifyNever(() => parcelles.obtenirParPotager(any()));
  });

  test('today\'s tasks are folded into one group per gesture', () async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('eau1', 'Arroser', EtatTache.aFaire, DateTime(2026, 6, 9, 8)),
        uneTache('eau2', 'Arroser', EtatTache.aFaire, DateTime(2026, 6, 9, 9)),
        uneTache('semis', 'Semer', EtatTache.aFaire, DateTime(2026, 6, 9, 14),
            type: TypeTache.semis),
      ],
    );

    final vue = await conteneur().read(accueilProvider.future);

    expect(vue.tachesDuJour, hasLength(3)); // raw list untouched
    expect(vue.gestesDuJour, hasLength(2)); // one line per gesture
    expect(vue.gestesDuJour.first.type, TypeTache.arrosage);
    expect(vue.gestesDuJour.first.nombre, 2);
    expect(vue.gestesDuJour.last.estSeule, isTrue);
    expect(vue.nombreTachesAFaire, 3); // counter still counts real tasks
  });

  test('ticking a geste completes every task left to do', () async {
    final a =
        uneTache('a', 'Arroser', EtatTache.aFaire, DateTime(2026, 6, 9, 8));
    final b =
        uneTache('b', 'Arroser', EtatTache.aFaire, DateTime(2026, 6, 9, 9));
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [a, b]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    final c = conteneur();
    final vue = await c.read(accueilProvider.future);

    await c.read(accueilProvider.notifier).basculerGeste(vue.gestesDuJour.single);

    expect([a, b].map((t) => t.estFaite), everyElement(isTrue));
    expect(a.dateRealisation, maintenant);
    verify(() => taches.sauvegarder(any())).called(2);
  });

  test('ticking a partially done geste spares the tasks already ticked',
      () async {
    final dejaFaite =
        uneTache('a', 'Arroser', EtatTache.terminee, DateTime(2026, 6, 9, 8));
    final restante =
        uneTache('b', 'Arroser', EtatTache.aFaire, DateTime(2026, 6, 9, 9));
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [dejaFaite, restante]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    final c = conteneur();
    final vue = await c.read(accueilProvider.future);

    await c.read(accueilProvider.notifier).basculerGeste(vue.gestesDuJour.single);

    expect(dejaFaite.estFaite, isTrue);
    expect(restante.estFaite, isTrue);
    verifyNever(() => taches.sauvegarder(dejaFaite));
  });

  test('ticking a fully done geste reopens all of it', () async {
    final a =
        uneTache('a', 'Arroser', EtatTache.terminee, DateTime(2026, 6, 9, 8));
    final b =
        uneTache('b', 'Arroser', EtatTache.terminee, DateTime(2026, 6, 9, 9));
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [a, b]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    final c = conteneur();
    final vue = await c.read(accueilProvider.future);

    await c.read(accueilProvider.notifier).basculerGeste(vue.gestesDuJour.single);

    expect([a, b].map((t) => t.estFaite), everyElement(isFalse));
  });
}
