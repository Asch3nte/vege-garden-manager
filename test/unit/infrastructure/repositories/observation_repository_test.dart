import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/observation.dart';
import 'package:pot_a_gerer/domain/enums/cible_observation.dart';
import 'package:pot_a_gerer/domain/enums/gravite_observation.dart';
import 'package:pot_a_gerer/domain/enums/type_observation.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/observation_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ObservationRepositoryImpl repo;
  final now = DateTime.utc(2026, 6, 10).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ObservationRepositoryImpl(db);
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
    await db.into(db.plantations).insert(PlantationsCompanion.insert(
        id: 'pl1',
        parcelleId: 'par1',
        planteId: 'tomate',
        dateMiseEnPlace: now,
        methode: 'repiquage',
        surfaceOccupeeValeur: 1,
        nombrePieds: 2,
        createdAt: now,
        updatedAt: now));
  });
  tearDown(() => db.close());

  Observation obs({
    String id = 'o1',
    CibleObservation cible = CibleObservation.plantation,
    String cibleId = 'pl1',
    bool resolu = false,
    DateTime? dateResolution,
  }) =>
      Observation(
        id: id,
        cible: cible,
        cibleId: cibleId,
        date: DateTime.utc(2026, 5, 15),
        type: TypeObservation.maladie,
        titre: 'Taches',
        gravite: GraviteObservation.eleve,
        resolu: resolu,
        dateResolution: dateResolution,
      );

  test('round-trips a plantation-targeted observation', () async {
    await repo.sauvegarder(obs());
    final o = (await repo.obtenirParCible(CibleObservation.plantation, 'pl1'))
        .single;
    expect(o.cible, CibleObservation.plantation);
    expect(o.cibleId, 'pl1');
    expect(o.type, TypeObservation.maladie);
    expect(o.gravite, GraviteObservation.eleve);
    expect(o.resolu, isFalse);
  });

  test('obtenirParCible discriminates the target', () async {
    await repo.sauvegarder(obs()); // targets plantation pl1
    expect(await repo.obtenirParCible(CibleObservation.potager, 'pot1'),
        isEmpty);
    expect(await repo.obtenirParCible(CibleObservation.parcelle, 'par1'),
        isEmpty);
  });

  test('round-trips a resolved observation', () async {
    await repo.sauvegarder(
        obs(resolu: true, dateResolution: DateTime.utc(2026, 5, 20)));
    final o = (await repo.obtenirParCible(CibleObservation.plantation, 'pl1'))
        .single;
    expect(o.resolu, isTrue);
    // Dates come back in local time (see `DateIso`) — compare instants.
    expect(
        o.dateResolution!.isAtSameMomentAs(DateTime.utc(2026, 5, 20)), isTrue);
  });

  test('obtenirNonResolues returns only unresolved', () async {
    await repo.sauvegarder(obs(id: 'a'));
    await repo.sauvegarder(
        obs(id: 'b', resolu: true, dateResolution: DateTime.utc(2026, 5, 20)));
    final list = await repo.obtenirNonResolues();
    expect(list.map((o) => o.id), ['a']);
  });

  test('supprimer soft-deletes', () async {
    await repo.sauvegarder(obs());
    await repo.supprimer('o1');
    expect(await repo.obtenirParCible(CibleObservation.plantation, 'pl1'),
        isEmpty);
  });
}
