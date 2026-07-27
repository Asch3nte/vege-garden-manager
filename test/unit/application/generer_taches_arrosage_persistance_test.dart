// End-to-end regression tests for the watering task generator, running against
// the **real** drift-backed task repository.
//
// The unit tests in `generer_taches_arrosage_test.dart` drive the use case with
// in-memory `Tache` objects, so they never exercise the storage round-trip. That
// is exactly where the "ticking a task instantly spawns an identical one" bug
// lived: tasks were written as UTC ISO-8601 and read back as UTC instants, so
// `_memeJour` compared a UTC calendar day against a local one, never recognised
// the existing task and recreated it on the next run.
//
// The clock here is deliberately **local** (that is what the app uses) so the
// tests fail on any machine whose timezone offset is non-zero if the round-trip
// ever becomes asymmetric again.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/calculer_besoin_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_notification_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/conseil_arrosage.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/plantation_repository_impl.dart';
import 'package:pot_a_gerer/infrastructure/repositories/tache_repository_impl.dart';

class _MockPlantations extends Mock implements AbstractPlantationRepository {}

class _MockPotager extends Mock implements AbstractPotagerRepository {}

class _MockNotifications extends Mock implements AbstractNotificationService {}

class _MockCalcul extends Mock implements CalculerBesoinArrosage {}

class _FakeLocalisation extends Fake implements Localisation {}

class _FakeNotificationLocale extends Fake implements NotificationLocale {}

class _FakePlantation extends Fake implements Plantation {}

void main() {
  late AppDatabase db;
  late TacheRepositoryImpl taches;
  late _MockPlantations plantations;
  late _MockPotager potager;
  late _MockNotifications notifications;
  late _MockCalcul calcul;
  late GenererTachesArrosage useCase;

  setUpAll(() {
    registerFallbackValue(_FakeLocalisation());
    registerFallbackValue(_FakeNotificationLocale());
    registerFallbackValue(_FakePlantation());
  });

  // Local clock, pinned at 07:00 today (before the 08:00 notification guard).
  final n = DateTime.now();
  final maintenant = DateTime(n.year, n.month, n.day, 7);
  final aujourdhui = DateTime(n.year, n.month, n.day);

  final unePlantation = Plantation(
    id: 'p-1',
    planteId: 'tomate',
    parcelleId: 'par1',
    dateMiseEnPlace: DateTime(2026, 4, 1),
    methode: MethodeMiseEnPlace.semisDirect,
    surfaceOccupee: Surface.enMetresCarres(0.5),
    nombrePieds: 2,
  );

  final unPotager = Potager(
    id: 'pot1',
    nom: 'Mon potager',
    zoneClimatique:
        const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
    dateCreation: DateTime(2026, 1, 1),
  );

  void repondConseil(ConseilArrosage conseil) {
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => conseil);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    taches = TacheRepositoryImpl(db);
    plantations = _MockPlantations();
    potager = _MockPotager();
    notifications = _MockNotifications();
    calcul = _MockCalcul();

    final seed = DateTime.utc(2026, 1, 1).toIso8601String();
    await db.into(db.potagers).insert(PotagersCompanion.insert(
        id: 'pot1',
        nom: 'Mon potager',
        climatType: 'oceanique',
        zoneRusticite: 'zone8',
        dateCreation: seed,
        createdAt: seed,
        updatedAt: seed));
    await db.into(db.parcelles).insert(ParcellesCompanion.insert(
        id: 'par1',
        nom: 'Zone 1',
        potagerId: 'pot1',
        type: 'bacSureleve',
        surfaceValeur: 4,
        surfaceUnite: 'm2',
        exposition: 'pleinSoleil',
        positionOrdre: 0,
        dateCreation: seed,
        createdAt: seed,
        updatedAt: seed));
    // Real row so the task's plantation FK resolves.
    await PlantationRepositoryImpl(db).sauvegarder(unePlantation);

    when(() => potager.obtenirPotagerActif()).thenAnswer((_) async => unPotager);
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation]);
    when(() => notifications.programmer(any())).thenAnswer((_) async {});
    when(() => notifications.annuler(any())).thenAnswer((_) async {});

    useCase = GenererTachesArrosage(
      plantations,
      potager,
      taches,
      notifications,
      calcul,
      maintenant: () => maintenant,
    );
  });
  tearDown(() => db.close());

  Future<List<dynamic>> tachesDeLaPlantation() =>
      taches.obtenirParCible(CibleTache.plantation, 'p-1');

  test('generates exactly one watering task, on today (local day)', () async {
    repondConseil(
        ConseilArrosage(urgence: UrgenceArrosage.arroserMaintenant, indiceBesoin: 0.9));

    await useCase.executer();

    final liste = await tachesDeLaPlantation();
    expect(liste, hasLength(1));
    expect(liste.single.datePrevue, aujourdhui);
    expect(liste.single.type, TypeTache.arrosage);
  });

  test('re-running without any change creates no duplicate', () async {
    repondConseil(
        ConseilArrosage(urgence: UrgenceArrosage.arroserMaintenant, indiceBesoin: 0.9));

    await useCase.executer();
    await useCase.executer();
    await useCase.executer();

    expect(await tachesDeLaPlantation(), hasLength(1));
  });

  test('ticking the task off does not spawn an identical one', () async {
    // The reported bug: complete a watering task, the next generator run (any
    // dashboard/calendar load) immediately recreated it.
    repondConseil(
        ConseilArrosage(urgence: UrgenceArrosage.arroserMaintenant, indiceBesoin: 0.9));
    await useCase.executer();

    final tache = (await tachesDeLaPlantation()).single;
    tache.marquerFaite(maintenant);
    await taches.sauvegarder(tache);

    await useCase.executer();

    final apres = await tachesDeLaPlantation();
    expect(apres, hasLength(1));
    expect(apres.single.estFaite, isTrue);
  });

  test('a completed task survives repeated generator runs', () async {
    repondConseil(
        ConseilArrosage(urgence: UrgenceArrosage.arroserMaintenant, indiceBesoin: 0.9));
    await useCase.executer();
    final tache = (await tachesDeLaPlantation()).single;
    tache.marquerFaite(maintenant);
    await taches.sauvegarder(tache);

    for (var i = 0; i < 5; i++) {
      await useCase.executer();
    }

    expect(await tachesDeLaPlantation(), hasLength(1));
  });

  test('a "bientot" advice plans a single task on today + N days', () async {
    repondConseil(ConseilArrosage(
        urgence: UrgenceArrosage.bientot,
        joursAvantArrosage: 2,
        indiceBesoin: 0.5));

    await useCase.executer();
    await useCase.executer();

    final liste = await tachesDeLaPlantation();
    expect(liste, hasLength(1));
    expect(liste.single.datePrevue, aujourdhui.add(const Duration(days: 2)));
    verifyNever(() => notifications.programmer(any()));
  });

  test('urgency dropping to pasNecessaire removes the pending task', () async {
    repondConseil(
        ConseilArrosage(urgence: UrgenceArrosage.arroserMaintenant, indiceBesoin: 0.9));
    await useCase.executer();
    expect(await tachesDeLaPlantation(), hasLength(1));

    repondConseil(
        ConseilArrosage(urgence: UrgenceArrosage.pasNecessaire, indiceBesoin: 0.1));
    await useCase.executer();

    expect(await tachesDeLaPlantation(), isEmpty);
  });
}
