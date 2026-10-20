import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/equipement.dart';
import 'package:pot_a_gerer/domain/enums/etat_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/equipement_repository_impl.dart';

void main() {
  late AppDatabase db;
  late EquipementRepositoryImpl repo;
  final now = DateTime.utc(2026, 5, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = EquipementRepositoryImpl(db);
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

  Equipement equip({
    String id = 'eq1',
    String? parcelleId,
    TypeEquipement type = TypeEquipement.oya,
    DateTime? dateRetrait,
  }) =>
      Equipement(
        id: id,
        nom: 'Oya 5L',
        potagerId: 'pot1',
        parcelleId: parcelleId,
        type: type,
        dateInstallation: DateTime.utc(2026, 4, 10),
        dateRetrait: dateRetrait,
      );

  test('round-trips a transverse (parcelle-less) equipment', () async {
    await repo.sauvegarder(equip());
    final e = (await repo.obtenirParPotager('pot1')).single;
    expect(e.id, 'eq1');
    expect(e.estTransverse, isTrue);
    expect(e.type, TypeEquipement.oya);
    expect(e.etat, EtatEquipement.bon); // default
    expect(e.estEnService, isTrue);
  });

  test('obtenirParParcelle returns only that parcelle\'s equipment', () async {
    await repo.sauvegarder(equip(id: 'transverse'));
    await repo.sauvegarder(equip(id: 'attache', parcelleId: 'par1'));
    final list = await repo.obtenirParParcelle('par1');
    expect(list.map((e) => e.id), ['attache']);
  });

  test('round-trips a retired equipment (kept for history)', () async {
    await repo.sauvegarder(equip(dateRetrait: DateTime.utc(2026, 4, 30)));
    final e = (await repo.obtenirParId('eq1'))!;
    expect(e.estEnService, isFalse);
    // Dates come back in local time (see `DateIso`) — compare instants.
    expect(e.dateRetrait!.isAtSameMomentAs(DateTime.utc(2026, 4, 30)), isTrue);
  });

  test('sauvegarder updates an existing equipment', () async {
    final e = equip();
    await repo.sauvegarder(e);
    e.changerEtat(EtatEquipement.aRemplacer);
    await repo.sauvegarder(e);
    expect((await repo.obtenirParId('eq1'))!.etat, EtatEquipement.aRemplacer);
  });

  test('supprimer soft-deletes', () async {
    await repo.sauvegarder(equip());
    await repo.supprimer('eq1');
    expect(await repo.obtenirParId('eq1'), isNull);
    expect(await repo.obtenirParPotager('pot1'), isEmpty);
  });

  test('sauvegarder keeps the original creation timestamps', () async {
    final entite = equip();
    await repo.sauvegarder(entite);
    await db.customStatement(
        "UPDATE equipements SET created_at = '2026-09-01T00:00:00.000Z', date_creation = '2026-09-01T00:00:00.000Z' WHERE id = '${entite.id}'");

    await repo.sauvegarder(entite);

    final row = await db
        .customSelect("SELECT created_at, date_creation FROM equipements WHERE id = '${entite.id}'")
        .getSingle();
    expect(row.data, {'created_at': '2026-09-01T00:00:00.000Z', 'date_creation': '2026-09-01T00:00:00.000Z'});
  });

  test('supprimer cascades to the tasks and reminders targeting it', () async {
    await repo.sauvegarder(equip());
    await repo.sauvegarder(equip(id: 'eq2'));
    Future<void> tache(String id, String equipementId) =>
        db.into(db.taches).insert(TachesCompanion.insert(
              id: id,
              titre: 'Entretien',
              type: 'entretienEquipement',
              datePrevue: now,
              dateCreation: now,
              createdAt: now,
              updatedAt: now,
              equipementId: Value(equipementId),
            ));
    await tache('t_eq1', 'eq1');
    await tache('t_eq2', 'eq2');
    await db.into(db.rappels).insert(RappelsCompanion.insert(
          id: 'r_eq1',
          titre: 'Remplir',
          typeTacheGeneree: 'entretienEquipement',
          dateDebut: now,
          typeRecurrence: 'quotidien',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
          equipementId: const Value('eq1'),
        ));

    await repo.supprimer('eq1');

    Future<String?> supprimeLe(TableInfo<Table, dynamic> table, String id) async =>
        (await db
                .customSelect(
                    'SELECT deleted_at FROM ${table.actualTableName} WHERE id = ?',
                    variables: [Variable<String>(id)])
                .getSingle())
            .data['deleted_at'] as String?;
    expect(await supprimeLe(db.taches, 't_eq1'), isNotNull);
    expect(await supprimeLe(db.rappels, 'r_eq1'), isNotNull);
    expect(await supprimeLe(db.taches, 't_eq2'), isNull);
  });
}
