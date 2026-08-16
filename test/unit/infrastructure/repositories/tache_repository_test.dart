import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/tache_repository_impl.dart';

void main() {
  late AppDatabase db;
  late TacheRepositoryImpl repo;
  final now = DateTime.utc(2026, 5, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TacheRepositoryImpl(db);
    await db.into(db.potagers).insert(PotagersCompanion.insert(
        id: 'pot1',
        nom: 'J',
        climatType: 'oceanique',
        zoneRusticite: 'zone8',
        dateCreation: now,
        createdAt: now,
        updatedAt: now));
    await db.into(db.parcelles).insert(ParcellesCompanion.insert(
        id: 'par1',
        nom: 'P',
        potagerId: 'pot1',
        type: 'bacSureleve',
        surfaceValeur: 4,
        surfaceUnite: 'm2',
        exposition: 'pleinSoleil',
        positionOrdre: 0,
        dateCreation: now,
        createdAt: now,
        updatedAt: now));
  });
  tearDown(() => db.close());

  Tache tache({
    String id = 't1',
    CibleTache cible = CibleTache.parcelle,
    String cibleId = 'par1',
    DateTime? datePrevue,
    String? rappelOrigineId,
    EtatTache etat = EtatTache.aFaire,
    DateTime? dateRealisation,
  }) =>
      Tache(
        id: id,
        titre: 'Arroser',
        type: TypeTache.arrosage,
        cible: cible,
        cibleId: cibleId,
        datePrevue: datePrevue ?? DateTime.utc(2026, 6, 10),
        etat: etat,
        dateRealisation: dateRealisation,
        rappelOrigineId: rappelOrigineId,
      );

  test('round-trips a parcelle-targeted task', () async {
    await repo.sauvegarder(tache());
    final t = (await repo.obtenirParCible(CibleTache.parcelle, 'par1')).single;
    expect(t.cible, CibleTache.parcelle);
    expect(t.cibleId, 'par1');
    expect(t.type, TypeTache.arrosage);
    expect(t.estFaite, isFalse);
  });

  test('obtenirParCible discriminates the polymorphic target', () async {
    await repo.sauvegarder(tache(cible: CibleTache.potager, cibleId: 'pot1'));
    expect(await repo.obtenirParCible(CibleTache.parcelle, 'par1'), isEmpty);
    expect(
        (await repo.obtenirParCible(CibleTache.potager, 'pot1')).single.cibleId,
        'pot1');
  });

  test('round-trips a completed task', () async {
    await repo.sauvegarder(tache(
      etat: EtatTache.terminee,
      dateRealisation: DateTime.utc(2026, 6, 11),
    ));
    final t = (await repo.obtenirParId('t1'))!;
    expect(t.estFaite, isTrue);
    // Dates come back in local time (see `DateIso`), so compare instants.
    expect(t.dateRealisation!.isAtSameMomentAs(DateTime.utc(2026, 6, 11)),
        isTrue);
  });

  test('obtenirEntreDates filters by planned date inclusively', () async {
    await repo.sauvegarder(tache(id: 'early', datePrevue: DateTime.utc(2026, 6, 1)));
    await repo.sauvegarder(tache(id: 'mid', datePrevue: DateTime.utc(2026, 6, 10)));
    await repo.sauvegarder(tache(id: 'late', datePrevue: DateTime.utc(2026, 6, 20)));

    final list = await repo.obtenirEntreDates(
        DateTime.utc(2026, 6, 5), DateTime.utc(2026, 6, 15));
    expect(list.map((t) => t.id), ['mid']);
  });

  test('obtenirParRappel returns the generated tasks', () async {
    await repo.sauvegarder(tache(id: 'gen', rappelOrigineId: 'rap1'));
    await repo.sauvegarder(tache(id: 'standalone'));
    final list = await repo.obtenirParRappel('rap1');
    expect(list.map((t) => t.id), ['gen']);
  });

  test('a local planned date round-trips to the same local day', () async {
    // Regression: dates are stored as UTC ISO-8601; reading them back without
    // converting to local returned the previous (or next) calendar day for any
    // non-zero timezone offset, which broke every day-level comparison.
    final local = DateTime(2026, 6, 10);
    await repo.sauvegarder(tache(datePrevue: local));
    final t = (await repo.obtenirParId('t1'))!;
    expect(t.datePrevue, local);
    expect(t.datePrevue.day, local.day);
  });

  test('a local completion date round-trips to the same local day', () async {
    final local = DateTime(2026, 6, 10, 18, 30);
    await repo.sauvegarder(tache(
      datePrevue: local,
      etat: EtatTache.terminee,
      dateRealisation: local,
    ));
    expect((await repo.obtenirParId('t1'))!.dateRealisation, local);
  });

  test('supprimer soft-deletes', () async {
    await repo.sauvegarder(tache());
    await repo.supprimer('t1');
    expect(await repo.obtenirParId('t1'), isNull);
  });
}
