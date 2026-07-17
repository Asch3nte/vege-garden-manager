import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/calculer_besoin_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
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

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockFiche extends Mock implements FichePlante {}

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
  late MockFiches fiches;
  late MockCalculerBesoinArrosage calcul;
  late GenererTachesArrosage useCase;

  /// Stubs the catalogue so any plant sheet resolves to a common name derived
  /// from its id ("tomate" → "Tomate"), unless [nomsParPlanteId] overrides it.
  /// Pass `null` for a given id to simulate a missing sheet.
  void stubFiches([Map<String, String?>? nomsParPlanteId]) {
    when(() => fiches.obtenirParId(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as String;
      final String? nom = nomsParPlanteId != null && nomsParPlanteId.containsKey(id)
          ? nomsParPlanteId[id]
          : '${id[0].toUpperCase()}${id.substring(1)}';
      if (nom == null) return null;
      final fiche = MockFiche();
      when(() => fiche.nomLocalise(any())).thenReturn(nom);
      return fiche;
    });
  }

  /// Stubs the preferences repository to return [prefs] (defaults = all
  /// notifications allowed, no do-not-disturb window).
  void stubPreferences([PreferencesUtilisateur? prefs]) {
    when(() => preferences.charger())
        .thenAnswer((_) async => prefs ?? PreferencesUtilisateur());
  }

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
    fiches = MockFiches();
    calcul = MockCalculerBesoinArrosage();
    stubPreferences();
    stubFiches();
    useCase = GenererTachesArrosage(plantations, potager, taches, notifications,
        preferences, fiches, calcul, maintenant: () => pinned07h);
  });

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      );

  Plantation unePlantation(String id, {String planteId = 'tomate'}) =>
      Plantation(
        id: id,
        planteId: planteId,
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
    // The task names its crop (from the catalogue) rather than a generic chore.
    expect(tache.titre, 'Arroser : Tomate');

    final notifCaptured =
        verify(() => notifications.programmer(captureAny())).captured;
    expect(notifCaptured, hasLength(1));
    final notif = notifCaptured.first as NotificationLocale;
    expect(notif.categorie, 'arrosage');
    // One daily recap notification, naming the crop in its title.
    expect(notif.id, startsWith('arrosage_recap_'));
    expect(notif.titre, 'Arroser Tomate');
    expect(notif.cibleRoute, '/calendrier');
  });

  test('several urgent crops → a SINGLE recap notification naming them all',
      () async {
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives()).thenAnswer((_) async => [
          unePlantation('p-1', planteId: 'tomate'),
          unePlantation('p-2', planteId: 'basilic'),
        ]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, any()))
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});
    when(() => notifications.programmer(any())).thenAnswer((_) async {});

    await useCase.executer();

    // Two tasks, but a single notification (spam kept to one).
    verify(() => taches.sauvegarder(any())).called(2);
    final notifs =
        verify(() => notifications.programmer(captureAny())).captured;
    expect(notifs, hasLength(1));
    final notif = notifs.single as NotificationLocale;
    expect(notif.titre, 'Arroser Tomate, Basilic');
    // Full list in the body (maximum detail).
    expect(notif.corps, "Cultures à arroser aujourd'hui : Tomate, Basilic.");
  });

  test('more crops than fit the title → first names + "+N", full list in body',
      () async {
    final noms = ['tomate', 'basilic', 'courgette', 'poivron'];
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives()).thenAnswer((_) async => [
          for (var i = 0; i < noms.length; i++)
            unePlantation('p-$i', planteId: noms[i]),
        ]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, any()))
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});
    when(() => notifications.programmer(any())).thenAnswer((_) async {});

    await useCase.executer();

    final notif = (verify(() => notifications.programmer(captureAny())).captured
        .single) as NotificationLocale;
    expect(notif.titre, 'Arroser Tomate, Basilic, Courgette +1');
    expect(notif.corps,
        "Cultures à arroser aujourd'hui : Tomate, Basilic, Courgette, Poivron.");
  });

  test('missing sheet → the unnamed crop still counts in the "+N" overflow',
      () async {
    stubFiches({'tomate': 'Tomate', 'basilic': null});
    when(() => potager.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => plantations.obtenirActives()).thenAnswer((_) async => [
          unePlantation('p-1', planteId: 'tomate'),
          unePlantation('p-2', planteId: 'basilic'),
        ]);
    when(() => calcul.executer(
              plantation: any(named: 'plantation'),
              localisation: any(named: 'localisation'),
            ))
        .thenAnswer((_) async => arroserMaintenant());
    when(() => taches.obtenirParCible(CibleTache.plantation, any()))
        .thenAnswer((_) async => []);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});
    when(() => notifications.programmer(any())).thenAnswer((_) async {});

    await useCase.executer();

    final notif = (verify(() => notifications.programmer(captureAny())).captured
        .single) as NotificationLocale;
    // Tomate named, the unresolved basilic folded into "+1".
    expect(notif.titre, 'Arroser Tomate +1');
  });

  test(
      'existing uncompleted task today → no duplicate task, recap still scheduled',
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
        .thenAnswer((_) async => [uneTacheArrosageAuj('p-1')]);
    when(() => notifications.programmer(any())).thenAnswer((_) async {});

    await useCase.executer();

    // The task is not duplicated, but the crop still needs watering today, so
    // the daily recap must still fire (its stable per-day id just replaces any
    // pending one — no stacking).
    verifyNever(() => taches.sauvegarder(any()));
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

  group('notification opt-outs (constraint #3)', () {
    /// Wires an urgent-watering plantation with no existing task, so a
    /// notification would be scheduled unless an opt-out suppresses it.
    void wireUrgent() {
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
    }

    test('master switch off → task still created, no notification', () async {
      wireUrgent();
      stubPreferences(
          PreferencesUtilisateur(notificationsGlobalesActives: false));

      await useCase.executer();

      verify(() => taches.sauvegarder(any())).called(1);
      verifyNever(() => notifications.programmer(any()));
    });

    test("'arrosage' category muted → task still created, no notification",
        () async {
      wireUrgent();
      stubPreferences(PreferencesUtilisateur(
          notificationsParCategorie: const {'arrosage': false}));

      await useCase.executer();

      verify(() => taches.sauvegarder(any())).called(1);
      verifyNever(() => notifications.programmer(any()));
    });

    test('another category muted → arrosage notification still scheduled',
        () async {
      wireUrgent();
      stubPreferences(PreferencesUtilisateur(
          notificationsParCategorie: const {'semis': false}));

      await useCase.executer();

      verify(() => notifications.programmer(any())).called(1);
    });

    test('do-not-disturb window covers 08:00 → no notification', () async {
      wireUrgent();
      // 07:30 → 09:00 contains the 08:00 push.
      stubPreferences(PreferencesUtilisateur(
          nePasDerangerDebut: '07:30', nePasDerangerFin: '09:00'));

      await useCase.executer();

      verify(() => taches.sauvegarder(any())).called(1);
      verifyNever(() => notifications.programmer(any()));
    });

    test('do-not-disturb window outside 08:00 → notification scheduled',
        () async {
      wireUrgent();
      // 22:00 → 07:00 does not contain the 08:00 push.
      stubPreferences(PreferencesUtilisateur(
          nePasDerangerDebut: '22:00', nePasDerangerFin: '07:00'));

      await useCase.executer();

      verify(() => notifications.programmer(any())).called(1);
    });
  });
}
