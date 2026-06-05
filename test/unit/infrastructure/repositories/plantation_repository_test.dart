import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/plantation_repository_impl.dart';

void main() {
  late AppDatabase db;
  late PlantationRepositoryImpl repo;
  final now = DateTime.utc(2026, 6, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PlantationRepositoryImpl(db);
    await db.into(db.potagers).insert(PotagersCompanion.insert(
          id: 'pot1',
          nom: 'Jardin',
          climatType: 'oceanique',
          zoneRusticite: 'zone8',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));
    await db.into(db.parcelles).insert(ParcellesCompanion.insert(
          id: 'par1',
          nom: 'Planche',
          potagerId: 'pot1',
          type: 'bacSureleve',
          surfaceValeur: 4,
          surfaceUnite: 'm2',
          exposition: 'pleinSoleil',
          positionOrdre: 0,
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));
  });
  tearDown(() => db.close());

  Plantation plantation({
    String id = 'pl1',
    StatutPlantation statut = StatutPlantation.enCours,
    DateTime? dateFin,
  }) =>
      Plantation(
        id: id,
        planteId: 'tomate',
        parcelleId: 'par1',
        dateMiseEnPlace: DateTime.utc(2026, 5, 1),
        methode: MethodeMiseEnPlace.repiquage,
        surfaceOccupee: Surface.enMetresCarres(1.5),
        nombrePieds: 3,
        statut: statut,
        dateFinReelle: dateFin,
      );

  test('round-trips an active plantation', () async {
    await repo.sauvegarder(plantation());
    final p = (await repo.obtenirParParcelle('par1')).single;
    expect(p.estActive(), isTrue);
    expect(p.surfaceOccupee, Surface.enMetresCarres(1.5));
    expect(p.nombrePieds, 3);
    expect(p.recoltes, isEmpty);
  });

  test('round-trips a terminated plantation with end date', () async {
    await repo.sauvegarder(plantation(
      statut: StatutPlantation.recoltee,
      dateFin: DateTime.utc(2026, 9, 1),
    ));
    final p = (await repo.obtenirParParcelle('par1')).single;
    expect(p.statut, StatutPlantation.recoltee);
    expect(p.dateFinReelle, DateTime.utc(2026, 9, 1));
  });

  test('obtenirActives returns only enCours plantations', () async {
    await repo.sauvegarder(plantation(id: 'a'));
    await repo.sauvegarder(plantation(
      id: 'b',
      statut: StatutPlantation.arrachee,
      dateFin: DateTime.utc(2026, 8, 1),
    ));
    final actives = await repo.obtenirActives();
    expect(actives.map((p) => p.id), ['a']);
  });

  test('supprimer cascades to harvests', () async {
    await repo.sauvegarder(plantation());
    await db.into(db.recoltes).insert(RecoltesCompanion.insert(
          id: 'r1',
          plantationId: 'pl1',
          dateRecolte: now,
          quantite: 1,
          unite: 'kg',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));

    await repo.supprimer('pl1');

    expect(await repo.obtenirParParcelle('par1'), isEmpty);
    final rec = await (db.select(db.recoltes)..where((t) => t.id.equals('r1')))
        .getSingle();
    expect(rec.deletedAt, isNotNull);
  });
}
