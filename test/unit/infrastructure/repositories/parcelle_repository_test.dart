import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/ph_sol.dart';
import 'package:pot_a_gerer/domain/enums/source_type_sol.dart';
import 'package:pot_a_gerer/domain/enums/teinte_zone.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/value_objects/couleur_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/dimensions_zone.dart';
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

  Parcelle parcelle(
          {String id = 'par1',
          int ordre = 0,
          CouleurZone couleur =
              const CouleurZone.teinte(TeinteZone.vertProfond)}) =>
      Parcelle(
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
        couleur: couleur,
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

  test('save then read round-trips a palette tint and a custom colour',
      () async {
    await repo.sauvegarder(parcelle(
        id: 'a', couleur: const CouleurZone.teinte(TeinteZone.bordeaux)));
    await repo.sauvegarder(
        parcelle(id: 'b', couleur: CouleurZone.personnalisee(0x12AB34)));

    expect((await repo.obtenirParId('a'))!.couleur,
        const CouleurZone.teinte(TeinteZone.bordeaux));
    expect((await repo.obtenirParId('b'))!.couleur,
        CouleurZone.personnalisee(0x12AB34));
  });

  test('an unknown or missing tint reads as the first palette tint',
      () async {
    await repo.sauvegarder(parcelle(id: 'a', ordre: 2));
    await db.customStatement(
        "UPDATE parcelles SET couleur_teinte = 'inconnue' WHERE id = 'a'");
    await repo.sauvegarder(parcelle(id: 'b', ordre: 3));
    await db.customStatement(
        "UPDATE parcelles SET couleur_teinte = NULL WHERE id = 'b'");

    const premiere = CouleurZone.teinte(TeinteZone.vertProfond);
    expect((await repo.obtenirParId('a'))!.couleur, premiere);
    expect((await repo.obtenirParId('b'))!.couleur, premiere);
  });

  test('save then read round-trips dimensions and water need', () async {
    final dimensions = DimensionsZone(longueurCm: 250, largeurCm: 100);
    await repo.sauvegarder(Parcelle(
      id: 'par1',
      nom: 'Planche',
      potagerId: 'pot1',
      type: TypeParcelle.pleineTerre,
      surface: dimensions.surface,
      exposition: NiveauSoleil.pleinSoleil,
      dimensions: dimensions,
      besoinEau: BesoinEau.modere,
    ));
    final p = (await repo.obtenirParId('par1'))!;
    expect(p.dimensions, dimensions);
    expect(p.besoinEau, BesoinEau.modere);
  });

  test('invalid dimensions or water need read as unknown, the zone kept',
      () async {
    await repo.sauvegarder(parcelle(id: 'a'));
    await db.customStatement(
        "UPDATE parcelles SET longueur_cm = 200, besoin_eau = 'inconnu' "
        "WHERE id = 'a'");
    await repo.sauvegarder(parcelle(id: 'b'));
    await db.customStatement(
        "UPDATE parcelles SET longueur_cm = 200, largeur_cm = 200 "
        "WHERE id = 'b'");

    for (final id in ['a', 'b']) {
      final p = (await repo.obtenirParId(id))!;
      expect(p.dimensions, isNull);
      expect(p.besoinEau, isNull);
      expect(p.surface, Surface.enMetresCarres(2.5));
    }
  });

  test('creation order breaks position ties', () async {
    await repo.sauvegarder(parcelle(id: 'b'));
    await db.customStatement(
        "UPDATE parcelles SET created_at = '2026-01-02' WHERE id = 'b'");
    await repo.sauvegarder(parcelle(id: 'a'));
    await db.customStatement(
        "UPDATE parcelles SET created_at = '2026-01-01' WHERE id = 'a'");

    expect((await repo.obtenirParPotager('pot1')).map((p) => p.id), ['a', 'b']);
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
              titre: const Value('Tâche'),
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

  test('sauvegarder keeps the original creation timestamps', () async {
    final entite = parcelle();
    await repo.sauvegarder(entite);
    await db.customStatement(
        "UPDATE parcelles SET created_at = '2026-09-01T00:00:00.000Z', date_creation = '2026-09-01T00:00:00.000Z' WHERE id = '${entite.id}'");

    await repo.sauvegarder(entite);

    final row = await db
        .customSelect("SELECT created_at, date_creation FROM parcelles WHERE id = '${entite.id}'")
        .getSingle();
    expect(row.data, {'created_at': '2026-09-01T00:00:00.000Z', 'date_creation': '2026-09-01T00:00:00.000Z'});
  });
}
