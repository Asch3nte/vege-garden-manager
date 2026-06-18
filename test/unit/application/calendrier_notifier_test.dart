import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/calendrier_notifier.dart';
import 'package:pot_a_gerer/application/state/calendrier_vue.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockTaches extends Mock implements AbstractTacheRepository {}

/// No-op stub: watering task generation is tested separately.
class _StubGenererTachesArrosage implements GenererTachesArrosage {
  @override
  Future<void> executer() async {}
}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class _FakeTache extends Fake implements Tache {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  // Monday 8 June 2026, 08:24 (matches the mock-up's reference day).
  final maintenant = DateTime(2026, 6, 8, 8, 24);

  late MockTaches taches;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockPotagers potagers;
  late MockFiches fiches;

  setUp(() {
    taches = MockTaches();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    potagers = MockPotagers();
    fiches = MockFiches();
    // Default: nothing resolves (targets render without a name). Individual
    // tests stub the lookups they exercise.
    when(() => parcelles.obtenirParId(any())).thenAnswer((_) async => null);
    when(() => plantations.obtenirParId(any())).thenAnswer((_) async => null);
    when(() => fiches.obtenirParId(any())).thenAnswer((_) async => null);
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
  });

  Tache uneTache(String id, DateTime quand, {EtatTache etat = EtatTache.aFaire}) =>
      Tache(
        id: id,
        titre: 'Tâche $id',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: quand,
        etat: etat,
        dateRealisation: etat == EtatTache.terminee ? quand : null,
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      tacheRepositoryProvider.overrideWithValue(taches),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      plantationRepositoryProvider.overrideWithValue(plantations),
      potagerRepositoryProvider.overrideWithValue(potagers),
      fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
      horlogeProvider.overrideWithValue(() => maintenant),
      genererTachesArrosageProvider
          .overrideWith((ref) async => _StubGenererTachesArrosage()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('default scope is a 7-day window from today', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    await conteneur().read(calendrierProvider.future);

    final captured =
        verify(() => taches.obtenirEntreDates(captureAny(), captureAny()))
            .captured;
    expect(captured[0], DateTime(2026, 6, 8));
    expect(captured[1], DateTime(2026, 6, 15)); // +7 days, exclusive
  });

  test('groups tasks by day, ordered by day then undone-first', () async {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('d9', DateTime(2026, 6, 9, 10)),
        uneTache('d8-done', DateTime(2026, 6, 8, 9), etat: EtatTache.terminee),
        uneTache('d8-late', DateTime(2026, 6, 8, 18)),
        uneTache('d8-early', DateTime(2026, 6, 8, 7)),
      ],
    );

    final vue = await conteneur().read(calendrierProvider.future);

    expect(vue.groupes, hasLength(2));
    expect(vue.groupes[0].jour, DateTime(2026, 6, 8));
    expect(
      vue.groupes[0].taches.map((t) => t.id),
      ['d8-early', 'd8-late', 'd8-done'],
    );
    expect(vue.groupes[1].jour, DateTime(2026, 6, 9));
    expect(vue.total, 4);
    expect(vue.faites, 1);
    expect(vue.restantes, 3);
  });

  test('switching to month scope widens the window to month end', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c.read(calendrierProvider.notifier).definirPortee(PorteeAgenda.mois);

    final captured =
        verify(() => taches.obtenirEntreDates(captureAny(), captureAny()))
            .captured;
    // Each assemble reads two windows (agenda + month grid); in month scope the
    // agenda window itself runs [8 June, 1 July).
    final paires = [
      for (var i = 0; i < captured.length; i += 2)
        (captured[i], captured[i + 1]),
    ];
    expect(paires, contains((DateTime(2026, 6, 8), DateTime(2026, 7, 1))));
  });

  test('exposes the displayed month and navigates between months', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    final c = conteneur();
    final vue = await c.read(calendrierProvider.future);
    expect(vue.moisAffiche, DateTime(2026, 6, 1));

    await c.read(calendrierProvider.notifier).moisSuivant();
    expect(c.read(calendrierProvider).value!.moisAffiche, DateTime(2026, 7, 1));

    await c.read(calendrierProvider.notifier).moisPrecedent();
    await c.read(calendrierProvider.notifier).moisPrecedent();
    expect(c.read(calendrierProvider).value!.moisAffiche, DateTime(2026, 5, 1));

    await c.read(calendrierProvider.notifier).revenirMoisActuel();
    expect(c.read(calendrierProvider).value!.moisAffiche, DateTime(2026, 6, 1));
  });

  test('groupePourJour returns the displayed month tasks by day', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [uneTache('m', DateTime(2026, 6, 20, 9))]);

    final vue = await conteneur().read(calendrierProvider.future);

    expect(vue.groupePourJour(DateTime(2026, 6, 20)), isNotNull);
    expect(vue.groupePourJour(DateTime(2026, 6, 21)), isNull);
  });

  test('filtering by type narrows both the agenda and the month', () async {
    Tache typee(String id, TypeTache type) => Tache(
          id: id,
          titre: 'Tâche $id',
          type: type,
          cible: CibleTache.parcelle,
          cibleId: 'z-1',
          datePrevue: DateTime(2026, 6, 8, 10),
        );
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        typee('arr', TypeTache.arrosage),
        typee('tai', TypeTache.taille),
      ],
    );

    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c
        .read(calendrierProvider.notifier)
        .definirFiltreType(TypeTache.taille);

    final vue = c.read(calendrierProvider).value!;
    expect(vue.groupes.single.taches.map((t) => t.id), ['tai']);
    expect(vue.groupePourJour(DateTime(2026, 6, 8))!.taches.map((t) => t.id),
        ['tai']);
  });

  test('ticking a task marks it done and persists it', () async {
    final tache = uneTache('t1', DateTime(2026, 6, 8, 10));
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c.read(calendrierProvider.notifier).cocher(tache);

    expect(tache.estFaite, isTrue);
    expect(tache.dateRealisation, maintenant);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  test('ticking a done task reopens it and persists it', () async {
    final tache =
        uneTache('t1', DateTime(2026, 6, 8, 10), etat: EtatTache.terminee);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c.read(calendrierProvider.notifier).cocher(tache);

    expect(tache.estFaite, isFalse);
    expect(tache.dateRealisation, isNull);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  test('deleting a task removes it and reloads', () async {
    final tache = uneTache('t1', DateTime(2026, 6, 8, 10));
    var taches_ = [tache];
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => taches_);
    when(() => taches.supprimer(any())).thenAnswer((_) async {
      taches_ = [];
    });

    final c = conteneur();
    await c.read(calendrierProvider.future);

    await c.read(calendrierProvider.notifier).supprimer(tache);

    verify(() => taches.supprimer('t1')).called(1);
    expect(c.read(calendrierProvider).value!.vide, isTrue);
  });

  test('resolves target names: zone, crop and garden', () async {
    Tache cible(String id, CibleTache cible, String cibleId) => Tache(
          id: id,
          titre: 'Tâche $id',
          type: TypeTache.arrosage,
          cible: cible,
          cibleId: cibleId,
          datePrevue: DateTime(2026, 6, 8, 10),
        );
    final tZone = cible('z', CibleTache.parcelle, 'z-1');
    final tCulture = cible('c', CibleTache.plantation, 'pl-1');
    final tJardin = cible('j', CibleTache.potager, 'pot-1');
    final tInconnu = cible('e', CibleTache.equipement, 'eq-9');

    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tZone, tCulture, tJardin, tInconnu]);
    when(() => parcelles.obtenirParId('z-1')).thenAnswer(
      (_) async => Parcelle(
        id: 'z-1',
        nom: 'Carré nord',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      ),
    );
    when(() => plantations.obtenirParId('pl-1')).thenAnswer(
      (_) async => Plantation(
        id: 'pl-1',
        planteId: 'tomate',
        parcelleId: 'z-1',
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 2,
      ),
    );
    when(() => fiches.obtenirParId('tomate')).thenAnswer(
      (_) async => FichePlante(
        id: 'tomate',
        nomScientifique: 'Solanum lycopersicum',
        familleBotanique: 'Solanaceae',
        categorie: CategoriePlante.legume,
        usages: const {UsagePlante.alimentaire},
        nomsLocalises: const {'fr': 'Tomate'},
        besoins: BesoinsCulture(
          eau: BesoinEau.eleve,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 7,
        ),
        espacementCm: 60,
        dureeAvantRecolteJoursMin: 70,
        dureeAvantRecolteJoursMax: 90,
        periodes: const {},
      ),
    );
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      ),
    );

    final vue = await conteneur().read(calendrierProvider.future);

    expect(vue.cibleNom(tZone), 'Carré nord');
    expect(vue.cibleNom(tCulture), 'Tomate'); // crop / variety, via its fiche
    expect(vue.cibleNom(tJardin), 'Mon potager');
    expect(vue.cibleNom(tInconnu), isNull); // equipment has no screen yet
  });

  test('empty window is flagged', () async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    final vue = await conteneur().read(calendrierProvider.future);

    expect(vue.vide, isTrue);
    expect(vue.groupes, isEmpty);
  });
}
