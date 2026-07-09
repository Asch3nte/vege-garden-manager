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
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_notification_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
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

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

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
  late MockPreferences preferences;
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
    preferences = MockPreferences();
    calcul = MockCalculerBesoinArrosage();
    // Default preferences: master on, no category muted, no do-not-disturb —
    // the notification filter is a pass-through unless a test overrides this.
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    useCase = GenererTachesArrosage(plantations, potager, taches, notifications,
        preferences, calcul, maintenant: () => pinned07h);
  });

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
    when(() => notifications.programmer(any())).thenAnswer((_) async {});

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
    expect(notif.id, startsWith('arrosage_p-1_'));
  });

  test('master switch off → task created but no notification scheduled',
      () async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(notificationsGlobalesActives: false),
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
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await useCase.executer();

    // The task is still materialized (the opt-out only gates push notifications).
    verify(() => taches.sauvegarder(any())).called(1);
    verifyNever(() => notifications.programmer(any()));
  });

  test('arrosage category muted → task created but no notification', () async {
    when(() => preferences.charger()).thenAnswer(
      (_) async =>
          PreferencesUtilisateur(notificationsParCategorie: {'arrosage': false}),
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
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await useCase.executer();

    verify(() => taches.sauvegarder(any())).called(1);
    verifyNever(() => notifications.programmer(any()));
  });

  test('automatic weather off → advice computed with an undefined location',
      () async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(meteoAutoActive: false),
    );
    when(() => potager.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
        localisation: Localisation.gps(latitude: 48.85, longitude: 2.35),
      ),
    );
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

    // The engine still runs, but with an undefined location → no Open-Meteo call.
    final loc = verify(() => calcul.executer(
          plantation: any(named: 'plantation'),
          localisation: captureAny(named: 'localisation'),
        )).captured.single as Localisation;
    expect(loc.estDefinie, isFalse);
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
    verifyNever(() => notifications.programmer(any()));
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
}
