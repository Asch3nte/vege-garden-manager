import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/calculer_besoin_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_notification_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/conseil_arrosage.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockPotager extends Mock implements AbstractPotagerRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockNotifications extends Mock implements AbstractNotificationService {}

class MockCalculerBesoinArrosage extends Mock
    implements CalculerBesoinArrosage {}

class _FakeLocalisation extends Fake implements Localisation {}

class _FakeTache extends Fake implements Tache {}

class _FakeNotificationLocale extends Fake implements NotificationLocale {}

class _FakePlantation extends Fake implements Plantation {}

void main() {
  late MockPlantations plantations;
  late MockPotager potager;
  late MockTaches taches;
  late MockNotifications notifications;
  late MockCalculerBesoinArrosage calcul;
  late GenererTachesArrosage useCase;

  setUpAll(() {
    registerFallbackValue(_FakeLocalisation());
    registerFallbackValue(_FakeTache());
    registerFallbackValue(_FakeNotificationLocale());
    registerFallbackValue(_FakePlantation());
    registerFallbackValue(CibleTache.plantation);
  });

  // Pinned clock at 07:00 so the 08:00 notification guard is always in the future.
  final DateTime pinned07h = DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().day, 7, 0);

  setUp(() {
    plantations = MockPlantations();
    potager = MockPotager();
    taches = MockTaches();
    notifications = MockNotifications();
    calcul = MockCalculerBesoinArrosage();
    useCase = GenererTachesArrosage(plantations, potager, taches, notifications,
        calcul, maintenant: () => pinned07h);
    // The day's single watering notification is (re)scheduled or cancelled on
    // every run, so both calls must be stubbed everywhere.
    when(() => notifications.programmer(any())).thenAnswer((_) async {});
    when(() => notifications.annuler(any())).thenAnswer((_) async {});
  });


  /// `yyyy-MM-dd` of [d], as used in the day-scoped notification id.
  String jourIso(DateTime d) => '${d.year.toString().padLeft(4, '0')}'
      '-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      );

  Plantation unePlantation(String id) => Plantation(
        id: id,
        planteId: 'tomate',
        parcelleId: 'z-1',
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 2,
      );

  Tache uneTacheArrosageAuj(String plantationId) => Tache(
        id: 'ta-$plantationId',
        titre: 'Arroser',
        type: TypeTache.arrosage,
        cible: CibleTache.plantation,
        cibleId: plantationId,
        datePrevue: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ),
        priorite: PrioriteTache.urgente,
      );

  ConseilArrosage arroserMaintenant() => ConseilArrosage(
        urgence: UrgenceArrosage.arroserMaintenant,
        joursAvantArrosage: 0,
        indiceBesoin: 0.9,
      );

  ConseilArrosage bientot() => ConseilArrosage(
        urgence: UrgenceArrosage.bientot,
        joursAvantArrosage: 2,
        indiceBesoin: 0.5,
      );

  ConseilArrosage pasNecessaire() => ConseilArrosage(
        urgence: UrgenceArrosage.pasNecessaire,
        indiceBesoin: 0.1,
      );

  Tache uneTacheArrosageJour(String plantationId, DateTime datePrevue,
          {bool faite = false}) =>
      Tache(
        id: 'ta-${plantationId}_${datePrevue.day}',
        titre: 'Arroser',
        type: TypeTache.arrosage,
        cible: CibleTache.plantation,
        cibleId: plantationId,
        datePrevue: datePrevue,
        priorite: PrioriteTache.normale,
        etat: faite ? EtatTache.terminee : EtatTache.aFaire,
        dateRealisation: faite ? datePrevue : null,
      );

  test('no active garden → no task created', () async {
    when(() => potager.obtenirPotagerActif()).thenAnswer((_) async => null);

    await useCase.executer();

    verifyNever(() => taches.sauvegarder(any()));
    verifyNever(() => notifications.programmer(any()));
  });

  test(
      'arroserMaintenant + no existing task → task saved + notification scheduled',
      () async {
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await useCase.executer();

    final saved = verify(() => taches.sauvegarder(captureAny())).captured;
    expect(saved, hasLength(1));
    final tache = saved.first as Tache;
    expect(tache.type, TypeTache.arrosage);
    expect(tache.cible, CibleTache.plantation);
    expect(tache.cibleId, 'p-1');
    expect(tache.priorite, PrioriteTache.urgente);

    final notifCaptured =
        verify(() => notifications.programmer(captureAny())).captured;
    expect(notifCaptured, hasLength(1));
    final notif = notifCaptured.first as NotificationLocale;
    expect(notif.categorie, 'arrosage');
    // Day-scoped id (not per plantation): one notification covers the day.
    expect(notif.id, 'arrosage_${jourIso(pinned07h)}');
    expect(notif.corps, contains('Une de vos cultures'));
  });

  test('existing uncompleted task today → no duplicate created', () async {
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [uneTacheArrosageAuj('p-1')]);

    await useCase.executer();

    verifyNever(() => taches.sauvegarder(any()));
    // The crop is still thirsty and its task still pending → the day's single
    // notification is (re)scheduled, even though no task was created.
    verify(() => notifications.programmer(any())).called(1);
  });

  test('pasNecessaire + existing pending task → task deleted', () async {
    final existante = uneTacheArrosageAuj('p-1');
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => pasNecessaire());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [existante]);
    when(() => taches.supprimer(any())).thenAnswer((_) async {});

    await useCase.executer();

    verify(() => taches.supprimer(existante.id)).called(1);
    verifyNever(() => taches.sauvegarder(any()));
  });

  test('bientot + no existing task → creates task for today+2, no notification',
      () async {
    final aujourd = DateTime(pinned07h.year, pinned07h.month, pinned07h.day);
    final dansDeuxJours = aujourd.add(const Duration(days: 2));
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => bientot());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await useCase.executer();

    final captured =
        verify(() => taches.sauvegarder(captureAny())).captured;
    expect(captured, hasLength(1));
    final tache = captured.first as Tache;
    expect(tache.datePrevue, dansDeuxJours);
    expect(tache.priorite, PrioriteTache.normale);
    verifyNever(() => notifications.programmer(any()));
  });

  test('bientot + existing today task → deletes today + creates today+2', () async {
    final aujourd = DateTime(pinned07h.year, pinned07h.month, pinned07h.day);
    final dansDeuxJours = aujourd.add(const Duration(days: 2));
    final tacheAujourd = uneTacheArrosageJour('p-1', aujourd);
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => bientot());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [tacheAujourd]);
    when(() => taches.supprimer(any())).thenAnswer((_) async {});
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await useCase.executer();

    verify(() => taches.supprimer(tacheAujourd.id)).called(1);
    final captured = verify(() => taches.sauvegarder(captureAny())).captured;
    final nouvelle = captured.first as Tache;
    expect(nouvelle.datePrevue, dansDeuxJours);
  });

  test('completed task today + still urgent → no new task (dedup guards check-off)',
      () async {
    final faite = Tache(
      id: 'ta-done',
      titre: 'Arroser',
      type: TypeTache.arrosage,
      cible: CibleTache.plantation,
      cibleId: 'p-1',
      datePrevue: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ),
      etat: EtatTache.terminee,
      dateRealisation: DateTime.now(),
    );
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [faite]);

    await useCase.executer();

    // User already watered the plant and ticked the task — must not recreate.
    verifyNever(() => taches.sauvegarder(any()));
    verifyNever(() => notifications.programmer(any()));
  });

  test('completed task today is not re-deleted on urgency drop (pasNecessaire)',
      () async {
    final faite = Tache(
      id: 'ta-done',
      titre: 'Arroser',
      type: TypeTache.arrosage,
      cible: CibleTache.plantation,
      cibleId: 'p-1',
      datePrevue: DateTime(pinned07h.year, pinned07h.month, pinned07h.day),
      etat: EtatTache.terminee,
      dateRealisation: pinned07h,
    );
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => pasNecessaire());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [faite]);

    await useCase.executer();

    // Completed tasks must never be removed, regardless of advice.
    verifyNever(() => taches.supprimer(any()));
    verifyNever(() => taches.sauvegarder(any()));
  });

  test('several thirsty crops schedule a single notification, counted',
      () async {
    // Regression: one notification per plantation meant five pings for five
    // crops. One per day now, carrying the count.
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives()).thenAnswer((_) async =>
        [unePlantation('p-1'), unePlantation('p-2'), unePlantation('p-3')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, any()))
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await useCase.executer();

    final captured =
        verify(() => notifications.programmer(captureAny())).captured;
    expect(captured, hasLength(1)); // not one per crop
    final notif = captured.single as NotificationLocale;
    expect(notif.id, 'arrosage_${jourIso(pinned07h)}');
    expect(notif.corps, contains('3 de vos cultures'));
    verifyNever(() => notifications.annuler(any()));
  });

  test('a day needing no watering cancels its notification', () async {
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => pasNecessaire());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => []);

    await useCase.executer();

    verify(() => notifications.annuler('arrosage_${jourIso(pinned07h)}'))
        .called(1);
    verifyNever(() => notifications.programmer(any()));
  });

  test('re-running rewrites the same day notification, never adds one',
      () async {
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1'), unePlantation('p-2')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    // Tasks already exist: nothing is created, but the notification stays exact.
    when(() => taches.obtenirParCible(CibleTache.plantation, any())).thenAnswer(
        (invocation) async =>
            [uneTacheArrosageAuj(invocation.positionalArguments[1] as String)]);

    await useCase.executer();
    await useCase.executer();

    final captured =
        verify(() => notifications.programmer(captureAny())).captured;
    // One per run, always the same id → the OS replaces it rather than stacking.
    expect(captured, hasLength(2));
    expect(
        captured.map((n) => (n as NotificationLocale).id).toSet(), hasLength(1));
    expect((captured.first as NotificationLocale).corps,
        contains('2 de vos cultures'));
    verifyNever(() => taches.sauvegarder(any()));
  });

  test('a crop already ticked off today is left out of the notification',
      () async {
    // Watering done and ticked at 07:00 → no 08:00 ping about it.
    final faite = Tache(
      id: 'ta-done',
      titre: 'Arroser',
      type: TypeTache.arrosage,
      cible: CibleTache.plantation,
      cibleId: 'p-1',
      datePrevue: DateTime(pinned07h.year, pinned07h.month, pinned07h.day),
      etat: EtatTache.terminee,
      dateRealisation: pinned07h,
    );
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1'), unePlantation('p-2')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [faite]);
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-2'))
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await useCase.executer();

    final captured =
        verify(() => notifications.programmer(captureAny())).captured;
    expect(captured, hasLength(1));
    // Only p-2 remains thirsty → singular wording, p-1 not counted.
    expect((captured.single as NotificationLocale).corps,
        contains('Une de vos cultures'));
  });

  test('every crop ticked off today cancels the notification', () async {
    final faite = Tache(
      id: 'ta-done',
      titre: 'Arroser',
      type: TypeTache.arrosage,
      cible: CibleTache.plantation,
      cibleId: 'p-1',
      datePrevue: DateTime(pinned07h.year, pinned07h.month, pinned07h.day),
      etat: EtatTache.terminee,
      dateRealisation: pinned07h,
    );
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives())
        .thenAnswer((_) async => [unePlantation('p-1')]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [faite]);

    await useCase.executer();

    verify(() => notifications.annuler('arrosage_${jourIso(pinned07h)}'))
        .called(1);
    verifyNever(() => notifications.programmer(any()));
  });
}
