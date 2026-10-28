@Tags(['dst'])
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/calculer_besoin_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/entities/rappel.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/jour_semaine.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_recurrence.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_notification_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_textes_notifications.dart';
import 'package:pot_a_gerer/domain/value_objects/conseil_arrosage.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/notification_locale.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/rappel_repository_impl.dart';
import 'package:pot_a_gerer/infrastructure/repositories/tache_repository_impl.dart';

class _MockPlantations extends Mock implements AbstractPlantationRepository {}

class _MockPotager extends Mock implements AbstractPotagerRepository {}

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockNotifications extends Mock implements AbstractNotificationService {}

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _MockFiches extends Mock implements AbstractFichePlanteRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockCalcul extends Mock implements CalculerBesoinArrosage {}

class _FakeLocalisation extends Fake implements Localisation {}

class _FakeTache extends Fake implements Tache {}

class _FakeNotificationLocale extends Fake implements NotificationLocale {}

class _FakePlantation extends Fake implements Plantation {}

class _Textes implements AbstractTextesNotifications {
  @override
  String get langue => 'fr';

  @override
  String titreRecapArrosage(List<String> noms, int total) => 't';

  @override
  String corpsRecapArrosage(List<String> noms, int total) => 'c';
}

typedef _Jour = (int, int, int);

/// Day before each 2026 switch: Europe (03-29, 10-25), Sydney (04-05, 10-04).
final _veilles = <String, DateTime>{
  'Europe spring': DateTime(2026, 3, 28),
  'Europe autumn': DateTime(2026, 10, 24),
  'Sydney autumn': DateTime(2026, 4, 4),
  'Sydney spring': DateTime(2026, 10, 3),
};

_Jour _cle(DateTime d) => (d.year, d.month, d.day);

_Jour _jourPlus(DateTime d, int n) {
  final u = DateTime.utc(d.year, d.month, d.day + n);
  return (u.year, u.month, u.day);
}

void main() {
  const delai = Timeout(Duration(seconds: 5));

  group('GenererTaches', () {
    late AppDatabase db;
    late RappelRepositoryImpl rappels;
    late TacheRepositoryImpl taches;
    late DateTime maintenant;
    late GenererTaches useCase;
    var compteur = 0;
    final seed = DateTime.utc(2026, 1, 1).toIso8601String();

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      rappels = RappelRepositoryImpl(db);
      taches = TacheRepositoryImpl(db);
      compteur = 0;
      useCase = GenererTaches(
        rappels,
        taches,
        genererId: () => 'tache-${compteur++}',
        maintenant: () => maintenant,
      );
      await db
          .into(db.potagers)
          .insert(
            PotagersCompanion.insert(
              id: 'pot1',
              nom: 'J',
              climatType: 'oceanique',
              zoneRusticite: 'zone8',
              dateCreation: seed,
              createdAt: seed,
              updatedAt: seed,
            ),
          );
    });
    tearDown(() => db.close());

    Rappel rappel(TypeRecurrence type, {int horizon = 7, DateTime? fin}) =>
        Rappel(
          id: 'r1',
          titre: 'T',
          typeTacheGeneree: TypeTache.arrosage,
          cible: CibleTache.potager,
          cibleId: 'pot1',
          dateDebut: DateTime(2026, 1, 1),
          dateFin: fin,
          typeRecurrence: type,
          intervalleJours: type == TypeRecurrence.personnalise ? 2 : null,
          joursSemaine: type == TypeRecurrence.hebdomadaire
              ? {JourSemaine.samedi, JourSemaine.dimanche, JourSemaine.lundi}
              : null,
          jourDuMois: type == TypeRecurrence.mensuel ? 29 : null,
          genererXJoursAvance: horizon,
        );

    Future<List<_Jour>> jours() async => [
      for (final t in await taches.obtenirParRappel('r1'))
        _cle(t.datePrevue.toLocal()),
    ];

    for (final MapEntry(key: nom, value: veille) in _veilles.entries) {
      test('$nom: daily, one task per day across the switch', () async {
        await rappels.sauvegarder(rappel(TypeRecurrence.quotidien));
        maintenant = DateTime(veille.year, veille.month, veille.day, 10);

        final creees = await useCase.executer();

        expect(creees, hasLength(8));
        expect(await jours(), [
          for (var i = 0; i <= 7; i++) _jourPlus(veille, i),
        ]);
      }, timeout: delai);

      test('$nom: a run each day over a week never duplicates a day', () async {
        await rappels.sauvegarder(rappel(TypeRecurrence.quotidien, horizon: 3));
        for (var i = 0; i < 7; i++) {
          final j = _jourPlus(veille, i);
          maintenant = DateTime(j.$1, j.$2, j.$3, 0, 30);
          await useCase.executer();
          maintenant = DateTime(j.$1, j.$2, j.$3, 23, 30);
          expect(await useCase.executer(), isEmpty);
        }
        expect(await jours(), [
          for (var i = 0; i <= 9; i++) _jourPlus(veille, i),
        ]);
      }, timeout: delai);

      test('$nom: dateFin on the switch day is included, none after', () async {
        final fin = DateTime(
          _jourPlus(veille, 1).$1,
          _jourPlus(veille, 1).$2,
          _jourPlus(veille, 1).$3,
        );
        await rappels.sauvegarder(rappel(TypeRecurrence.quotidien, fin: fin));
        maintenant = DateTime(veille.year, veille.month, veille.day, 10);

        await useCase.executer();

        expect(await jours(), [_cle(veille), _jourPlus(veille, 1)]);
      }, timeout: delai);

      for (final type in [
        TypeRecurrence.hebdomadaire,
        TypeRecurrence.personnalise,
        TypeRecurrence.mensuel,
        TypeRecurrence.ponctuel,
      ]) {
        test('$nom: ${type.name} yields the expected days once', () async {
          await rappels.sauvegarder(rappel(type, horizon: 14));
          maintenant = DateTime(veille.year, veille.month, veille.day, 10);
          final debut = DateTime.utc(2026, 1, 1);

          await useCase.executer();
          final second = await useCase.executer();

          final attendus = <_Jour>[];
          for (var i = 0; i <= 14; i++) {
            final u = DateTime.utc(veille.year, veille.month, veille.day + i);
            final ok = switch (type) {
              TypeRecurrence.hebdomadaire =>
                u.weekday == DateTime.saturday ||
                    u.weekday == DateTime.sunday ||
                    u.weekday == DateTime.monday,
              TypeRecurrence.personnalise =>
                u.difference(debut).inDays % 2 == 0,
              TypeRecurrence.mensuel => u.day == 29,
              _ => false,
            };
            if (ok) attendus.add((u.year, u.month, u.day));
          }
          expect(second, isEmpty);
          expect(await jours(), attendus);
        }, timeout: delai);
      }
    }
  });

  group('GenererTachesArrosage', () {
    late _MockPlantations plantations;
    late _MockPotager potager;
    late _MockTaches taches;
    late _MockNotifications notifications;
    late _MockPreferences preferences;
    late _MockFiches fiches;
    late _MockCalcul calcul;
    late _MockParcelles parcelles;
    late DateTime maintenant;
    late GenererTachesArrosage useCase;

    setUpAll(() {
      registerFallbackValue(_FakeLocalisation());
      registerFallbackValue(_FakeTache());
      registerFallbackValue(_FakeNotificationLocale());
      registerFallbackValue(_FakePlantation());
      registerFallbackValue(CibleTache.plantation);
    });

    setUp(() {
      plantations = _MockPlantations();
      potager = _MockPotager();
      taches = _MockTaches();
      notifications = _MockNotifications();
      preferences = _MockPreferences();
      fiches = _MockFiches();
      calcul = _MockCalcul();
      parcelles = _MockParcelles();
      final zone = _MockParcelle();
      when(() => zone.id).thenReturn('z-1');
      when(() => zone.potagerId).thenReturn('pot-1');
      when(
        () => parcelles.obtenirParPotager(any()),
      ).thenAnswer((_) async => [zone]);
      when(
        () => preferences.charger(),
      ).thenAnswer((_) async => PreferencesUtilisateur());
      when(() => fiches.obtenirParId(any())).thenAnswer((_) async => null);
      when(() => potager.obtenirTous()).thenAnswer(
        (_) async => [
          Potager(
            id: 'pot-1',
            nom: 'P',
            zoneClimatique: const ZoneClimatique(
              TypeClimat.oceanique,
              ZoneRusticite.zone8,
            ),
            dateCreation: DateTime(2026, 1, 1),
          ),
        ],
      );
      when(
        () => calcul.chargerFenetre(
          any(),
          meteoAutoActive: any(named: 'meteoAutoActive'),
        ),
      ).thenAnswer((_) async => const <PrevisionMeteo>[]);
      when(() => plantations.obtenirActives()).thenAnswer(
        (_) async => [
          Plantation(
            id: 'p-1',
            planteId: 'tomate',
            parcelleId: 'z-1',
            dateMiseEnPlace: DateTime(2026, 1, 1),
            methode: MethodeMiseEnPlace.semisDirect,
            surfaceOccupee: Surface.enMetresCarres(0.5),
            nombrePieds: 2,
          ),
        ],
      );
      when(
        () => taches.obtenirParCible(CibleTache.plantation, 'p-1'),
      ).thenAnswer((_) async => []);
      when(() => taches.sauvegarder(any())).thenAnswer((_) async {});
      when(() => notifications.programmer(any())).thenAnswer((_) async {});
      when(() => notifications.annuler(any())).thenAnswer((_) async {});
      useCase = GenererTachesArrosage(
        plantations,
        potager,
        parcelles,
        taches,
        notifications,
        preferences,
        fiches,
        calcul,
        _Textes(),
        maintenant: () => maintenant,
      );
    });

    void conseil(UrgenceArrosage urgence, {int? jours}) {
      when(
        () => calcul.executer(
          plantation: any(named: 'plantation'),
          localisation: any(named: 'localisation'),
          meteoAutoActive: any(named: 'meteoAutoActive'),
          fenetre: any(named: 'fenetre'),
        ),
      ).thenAnswer(
        (_) async => ConseilArrosage(
          urgence: urgence,
          joursAvantArrosage: jours,
          indiceBesoin: 0.9,
        ),
      );
    }

    for (final MapEntry(key: nom, value: veille) in _veilles.entries) {
      for (var decalage = 0; decalage <= 2; decalage++) {
        final jour = _jourPlus(veille, decalage);

        test(
          '$nom: water now on day +$decalage, one task and one notification',
          () async {
            conseil(UrgenceArrosage.arroserMaintenant, jours: 0);
            maintenant = DateTime(jour.$1, jour.$2, jour.$3, 7);

            await useCase.executer();

            final saved = verify(
              () => taches.sauvegarder(captureAny()),
            ).captured;
            expect(saved, hasLength(1));
            expect(_cle((saved.single as Tache).datePrevue), jour);
            final notif =
                verify(
                      () => notifications.programmer(captureAny()),
                    ).captured.single
                    as NotificationLocale;
            expect(_cle(notif.dateProgrammee), jour);
            expect(notif.dateProgrammee.hour, 8);
          },
          timeout: delai,
        );

        test(
          '$nom: water soon from day +$decalage lands 2 calendar days later',
          () async {
            conseil(UrgenceArrosage.bientot, jours: 2);
            maintenant = DateTime(jour.$1, jour.$2, jour.$3, 22);

            await useCase.executer();

            final saved = verify(
              () => taches.sauvegarder(captureAny()),
            ).captured;
            expect(saved, hasLength(1));
            final datee = (saved.single as Tache).datePrevue;
            expect(
              _cle(datee),
              _jourPlus(DateTime(jour.$1, jour.$2, jour.$3), 2),
            );
            expect(datee.hour, 0);
            verifyNever(() => notifications.programmer(any()));
          },
          timeout: delai,
        );
      }
    }
  });
}

class _MockParcelle extends Mock implements Parcelle {}
