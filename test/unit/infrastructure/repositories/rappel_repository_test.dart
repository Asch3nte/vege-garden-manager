import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/rappel.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_rappel.dart';
import 'package:pot_a_gerer/domain/enums/jour_semaine.dart';
import 'package:pot_a_gerer/domain/enums/type_recurrence.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/rappel_repository_impl.dart';

void main() {
  late AppDatabase db;
  late RappelRepositoryImpl repo;
  final now = DateTime.utc(2026, 5, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = RappelRepositoryImpl(db);
    await db.into(db.potagers).insert(PotagersCompanion.insert(
        id: 'pot1',
        nom: 'J',
        climatType: 'oceanique',
        zoneRusticite: 'zone8',
        dateCreation: now,
        createdAt: now,
        updatedAt: now));
  });
  tearDown(() => db.close());

  Rappel hebdo({
    String id = 'r1',
    Set<JourSemaine>? jours,
    EtatRappel etat = EtatRappel.actif,
  }) =>
      Rappel(
        id: id,
        titre: 'Visite hebdo',
        typeTacheGeneree: TypeTache.observation,
        cible: CibleTache.potager,
        cibleId: 'pot1',
        dateDebut: DateTime.utc(2026, 5, 4),
        typeRecurrence: TypeRecurrence.hebdomadaire,
        joursSemaine: jours ?? {JourSemaine.lundi, JourSemaine.jeudi},
        etat: etat,
      );

  test('round-trips a weekly reminder including its weekdays', () async {
    await repo.sauvegarder(hebdo());
    final r = (await repo.obtenirParId('r1'))!;
    expect(r.typeRecurrence, TypeRecurrence.hebdomadaire);
    expect(r.joursSemaine, {JourSemaine.lundi, JourSemaine.jeudi});
  });

  test('round-trips a one-off reminder (empty weekdays -> null column)',
      () async {
    final ponctuel = Rappel(
      id: 'r2',
      titre: 'Tailler',
      typeTacheGeneree: TypeTache.taille,
      cible: CibleTache.potager,
      cibleId: 'pot1',
      dateDebut: DateTime.utc(2026, 7, 1),
      typeRecurrence: TypeRecurrence.ponctuel,
    );
    await repo.sauvegarder(ponctuel);
    final r = (await repo.obtenirParId('r2'))!;
    expect(r.typeRecurrence, TypeRecurrence.ponctuel);
    expect(r.joursSemaine, isEmpty);
  });

  test('obtenirActifs returns only active reminders', () async {
    await repo.sauvegarder(hebdo(id: 'actif'));
    await repo.sauvegarder(hebdo(id: 'pause', etat: EtatRappel.enPause));
    final list = await repo.obtenirActifs();
    expect(list.map((r) => r.id), ['actif']);
  });

  test('obtenirParCible returns reminders for a target', () async {
    await repo.sauvegarder(hebdo());
    expect((await repo.obtenirParCible(CibleTache.potager, 'pot1')).single.id,
        'r1');
    expect(await repo.obtenirParCible(CibleTache.parcelle, 'par1'), isEmpty);
  });

  test('supprimer soft-deletes', () async {
    await repo.sauvegarder(hebdo());
    await repo.supprimer('r1');
    expect(await repo.obtenirParId('r1'), isNull);
    expect(await repo.obtenirActifs(), isEmpty);
  });
}
