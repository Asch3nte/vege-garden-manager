import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/ph_sol.dart';
import 'package:pot_a_gerer/domain/enums/source_type_sol.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/parcelle_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ParcelleRepositoryImpl repo;
  final now = DateTime.utc(2026, 6, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ParcelleRepositoryImpl(db);
    await db.into(db.potagers).insert(PotagersCompanion.insert(
          id: 'pot1',
          nom: 'Jardin',
          climatType: 'oceanique',
          zoneRusticite: 'zone8',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));
  });
  tearDown(() => db.close());

  Parcelle parcelle({String id = 'par1', int ordre = 0}) => Parcelle(
        id: id,
        nom: 'Planche',
        potagerId: 'pot1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2.5),
        exposition: NiveauSoleil.pleinSoleil,
        texture: TextureSol.argileux,
        textureSource: SourceTypeSol.deduitDuClimat,
        ph: PhSol.neutre,
        techniquesSol: {TechniqueSol.noDig, TechniqueSol.hugelkultur},
        cultureVerticale: true,
        ordre: ordre,
      );

  test('save then read round-trips soil, techniques and culture verticale',
      () async {
    await repo.sauvegarder(parcelle());
    final p = (await repo.obtenirParId('par1'))!;
    expect(p.surface, Surface.enMetresCarres(2.5));
    expect(p.texture, TextureSol.argileux);
    expect(p.textureSource, SourceTypeSol.deduitDuClimat);
    expect(p.ph, PhSol.neutre);
    expect(p.techniquesSol, {TechniqueSol.noDig, TechniqueSol.hugelkultur});
    expect(p.cultureVerticale, isTrue);
  });

  test('obtenirParPotager returns the potager parcelles, ordered', () async {
    await repo.sauvegarder(parcelle(id: 'b', ordre: 2));
    await repo.sauvegarder(parcelle(id: 'a', ordre: 1));
    final list = await repo.obtenirParPotager('pot1');
    expect(list.map((p) => p.id), ['a', 'b']);
  });

  test('supprimer soft-deletes the parcelle and cascades to children',
      () async {
    await repo.sauvegarder(parcelle());
    await db.into(db.plantations).insert(PlantationsCompanion.insert(
          id: 'pl1',
          parcelleId: 'par1',
          planteId: 'tomate',
          dateMiseEnPlace: now,
          methode: 'repiquage',
          surfaceOccupeeValeur: 1,
          nombrePieds: 2,
          createdAt: now,
          updatedAt: now,
        ));
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

    await repo.supprimer('par1');

    expect(await repo.obtenirParId('par1'), isNull);
    final pl =
        await (db.select(db.plantations)..where((t) => t.id.equals('pl1')))
            .getSingle();
    final rec = await (db.select(db.recoltes)..where((t) => t.id.equals('r1')))
        .getSingle();
    expect(pl.deletedAt, isNotNull);
    expect(rec.deletedAt, isNotNull);
  });

  test('supprimer cascades to planning rows of the parcelle and its children',
      () async {
    await repo.sauvegarder(parcelle(id: 'par1'));
    await repo.sauvegarder(parcelle(id: 'par2')); // control parcelle
    await db.into(db.plantations).insert(PlantationsCompanion.insert(
          id: 'pl1',
          parcelleId: 'par1',
          planteId: 'tomate',
          dateMiseEnPlace: now,
          methode: 'repiquage',
          surfaceOccupeeValeur: 1,
          nombrePieds: 2,
          createdAt: now,
          updatedAt: now,
        ));
    await db.into(db.equipements).insert(EquipementsCompanion.insert(
          id: 'eq1',
          nom: 'Tuteur',
          potagerId: 'pot1',
          type: 'tuteur',
          dateInstallation: now,
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
          parcelleId: const Value('par1'),
        ));

    Future<void> tache(String id, TachesCompanion cible) =>
        db.into(db.taches).insert(TachesCompanion.insert(
              id: id,
              titre: 'Tâche',
              type: 'arrosage',
              datePrevue: now,
              dateCreation: now,
              createdAt: now,
              updatedAt: now,
              parcelleId: cible.parcelleId,
              plantationId: cible.plantationId,
              equipementId: cible.equipementId,
            ));
    await tache('t_par', const TachesCompanion(parcelleId: Value('par1')));
    await tache('t_pla', const TachesCompanion(plantationId: Value('pl1')));
    await tache('t_eq', const TachesCompanion(equipementId: Value('eq1')));
    await tache('t_other', const TachesCompanion(parcelleId: Value('par2')));

    await repo.supprimer('par1');

    Future<String?> deletedAtTache(String id) async => (await (db.select(
                db.taches)
            ..where((t) => t.id.equals(id)))
        .getSingle())
        .deletedAt;

    for (final id in ['t_par', 't_pla', 't_eq']) {
      expect(await deletedAtTache(id), isNotNull, reason: 'tache $id');
    }
    expect(await deletedAtTache('t_other'), isNull); // other parcelle
  });
}
