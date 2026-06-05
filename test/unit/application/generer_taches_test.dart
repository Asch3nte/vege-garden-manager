import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches.dart';
import 'package:pot_a_gerer/domain/entities/rappel.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_rappel.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_recurrence.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/rappel_repository_impl.dart';
import 'package:pot_a_gerer/infrastructure/repositories/tache_repository_impl.dart';

void main() {
  late AppDatabase db;
  late RappelRepositoryImpl rappels;
  late TacheRepositoryImpl taches;
  late GenererTaches useCase;

  // Deterministic clock: "today" = 2026-06-05.
  final today = DateTime.utc(2026, 6, 5);
  var compteur = 0;
  final seed = DateTime.utc(2026, 5, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    rappels = RappelRepositoryImpl(db);
    taches = TacheRepositoryImpl(db);
    compteur = 0;
    useCase = GenererTaches(
      rappels,
      taches,
      genererId: () => 'tache-${compteur++}',
      maintenant: () => today,
    );
    await db.into(db.potagers).insert(PotagersCompanion.insert(
        id: 'pot1',
        nom: 'J',
        climatType: 'oceanique',
        zoneRusticite: 'zone8',
        dateCreation: seed,
        createdAt: seed,
        updatedAt: seed));
  });
  tearDown(() => db.close());

  Rappel rappel({
    String id = 'r1',
    required TypeRecurrence typeRecurrence,
    required DateTime dateDebut,
    int horizon = 7,
    EtatRappel etat = EtatRappel.actif,
  }) =>
      Rappel(
        id: id,
        titre: 'Arroser',
        typeTacheGeneree: TypeTache.arrosage,
        cible: CibleTache.potager,
        cibleId: 'pot1',
        dateDebut: dateDebut,
        typeRecurrence: typeRecurrence,
        genererXJoursAvance: horizon,
        etat: etat,
      );

  test('daily reminder generates one task per day over the horizon (inclusive)',
      () async {
    await rappels.sauvegarder(rappel(
      typeRecurrence: TypeRecurrence.quotidien,
      dateDebut: DateTime.utc(2026, 5, 1), // already started
      horizon: 7,
    ));

    final creees = await useCase.executer();

    // today .. today+7 inclusive = 8 days.
    expect(creees, hasLength(8));
    expect(await taches.obtenirParRappel('r1'), hasLength(8));
  });

  test('re-running is idempotent (no duplicates)', () async {
    await rappels.sauvegarder(rappel(
      typeRecurrence: TypeRecurrence.quotidien,
      dateDebut: DateTime.utc(2026, 5, 1),
    ));

    await useCase.executer();
    final secondRun = await useCase.executer();

    expect(secondRun, isEmpty);
    expect(await taches.obtenirParRappel('r1'), hasLength(8));
  });

  test('a cancelled task never reappears (strict dedup)', () async {
    await rappels.sauvegarder(rappel(
      typeRecurrence: TypeRecurrence.quotidien,
      dateDebut: DateTime.utc(2026, 5, 1),
    ));
    final creees = await useCase.executer();

    // The user cancels one occurrence.
    final cible = creees.first;
    cible.annuler();
    await taches.sauvegarder(cible);

    final rerun = await useCase.executer();

    expect(rerun, isEmpty); // not recreated
    final toutes = await taches.obtenirParRappel('r1');
    expect(toutes, hasLength(8)); // no new row
    final recharge = await taches.obtenirParId(cible.id);
    expect(recharge!.etat, EtatTache.annulee); // still cancelled
  });

  test('one-off reminder in the past generates nothing', () async {
    await rappels.sauvegarder(rappel(
      typeRecurrence: TypeRecurrence.ponctuel,
      dateDebut: DateTime.utc(2026, 5, 1), // before today
    ));
    expect(await useCase.executer(), isEmpty);
  });

  test('one-off reminder within the horizon generates a single task', () async {
    await rappels.sauvegarder(rappel(
      typeRecurrence: TypeRecurrence.ponctuel,
      dateDebut: DateTime.utc(2026, 6, 7), // within [today, today+7]
    ));
    final creees = await useCase.executer();
    expect(creees, hasLength(1));
    expect(creees.single.datePrevue, DateTime(2026, 6, 7));
  });

  test('paused reminders are ignored', () async {
    await rappels.sauvegarder(rappel(
      typeRecurrence: TypeRecurrence.quotidien,
      dateDebut: DateTime.utc(2026, 5, 1),
      etat: EtatRappel.enPause,
    ));
    expect(await useCase.executer(), isEmpty);
  });
}
