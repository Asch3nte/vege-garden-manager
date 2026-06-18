import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/source_localisation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_emplacement.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/potager_repository_impl.dart';

void main() {
  late AppDatabase db;
  late PotagerRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PotagerRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Potager potager({
    String id = 'p1',
    TypeEmplacement emplacement = TypeEmplacement.balcon,
    Localisation? localisation,
    DateTime? date,
  }) =>
      Potager(
        id: id,
        nom: 'Jardin',
        emplacement: emplacement,
        localisation: localisation ?? const Localisation.nonDefinie(),
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: date ?? DateTime.utc(2026, 3, 1),
      );

  test('save then read round-trips (shallow, no parcelles)', () async {
    await repo.sauvegarder(potager(
      localisation: Localisation.gps(latitude: 47.21, longitude: -1.55),
    ));
    final relu = (await repo.obtenirTous()).single;
    expect(relu.nom, 'Jardin');
    expect(relu.emplacement, TypeEmplacement.balcon);
    expect(relu.localisation.source, SourceLocalisation.gps);
    expect(relu.localisation.latitude, 47.21);
    expect(relu.zoneClimatique.type, TypeClimat.oceanique);
    expect(relu.zoneClimatique.rusticite, ZoneRusticite.zone8);
    expect(relu.parcelles, isEmpty);
  });

  test('undefined localisation round-trips (opt-out preserved)', () async {
    await repo.sauvegarder(potager());
    final relu = (await repo.obtenirTous()).single;
    expect(relu.localisation.estDefinie, isFalse);
    expect(relu.localisation.source, SourceLocalisation.nonDefinie);
  });

  test('manual localisation keeps the city', () async {
    await repo.sauvegarder(potager(
      localisation: Localisation.manuelle(
          ville: 'Nantes', latitude: 47.21, longitude: -1.55),
    ));
    final relu = (await repo.obtenirTous()).single;
    expect(relu.localisation.source, SourceLocalisation.manuelle);
    expect(relu.localisation.ville, 'Nantes');
  });

  test('sauvegarder upserts (no duplicate)', () async {
    await repo.sauvegarder(potager());
    await repo.sauvegarder(potager()); // same id
    expect(await repo.obtenirTous(), hasLength(1));
  });

  test('obtenirPotagerActif returns the earliest non-deleted', () async {
    await repo.sauvegarder(potager(id: 'b', date: DateTime.utc(2026, 5, 1)));
    await repo.sauvegarder(potager(id: 'a', date: DateTime.utc(2026, 1, 1)));
    expect((await repo.obtenirPotagerActif())!.id, 'a');
  });

  test('supprimer cascades to the whole hierarchy and its planning rows',
      () async {
    final now = DateTime.utc(2026, 6, 1).toIso8601String();
    await repo.sauvegarder(potager(id: 'p1'));
    await repo.sauvegarder(potager(id: 'p2')); // control, must survive

    await db.into(db.parcelles).insert(ParcellesCompanion.insert(
          id: 'pa1',
          nom: 'Planche',
          potagerId: 'p1',
          type: 'pleineTerre',
          surfaceValeur: 1,
          surfaceUnite: 'm2',
          exposition: 'pleinSoleil',
          positionOrdre: 0,
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));
    await db.into(db.plantations).insert(PlantationsCompanion.insert(
          id: 'pl1',
          parcelleId: 'pa1',
          planteId: 'LEG-001',
          dateMiseEnPlace: now,
          methode: 'semisDirect',
          surfaceOccupeeValeur: 1,
          nombrePieds: 1,
          createdAt: now,
          updatedAt: now,
        ));
    // Potager-level equipement (parcelleId null) — must still be caught.
    await db.into(db.equipements).insert(EquipementsCompanion.insert(
          id: 'eq1',
          nom: 'Oya',
          potagerId: 'p1',
          type: 'oya',
          dateInstallation: now,
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));

    // One task per kind of target, plus a reminder and an observation.
    Future<void> tache(String id, TachesCompanion cible) =>
        db.into(db.taches).insert(TachesCompanion.insert(
              id: id,
              titre: 'Tâche',
              type: 'arrosage',
              datePrevue: now,
              dateCreation: now,
              createdAt: now,
              updatedAt: now,
              potagerId: cible.potagerId,
              parcelleId: cible.parcelleId,
              plantationId: cible.plantationId,
              equipementId: cible.equipementId,
            ));
    await tache('t_pot', const TachesCompanion(potagerId: Value('p1')));
    await tache('t_par', const TachesCompanion(parcelleId: Value('pa1')));
    await tache('t_pla', const TachesCompanion(plantationId: Value('pl1')));
    await tache('t_eq', const TachesCompanion(equipementId: Value('eq1')));
    await tache('t_other', const TachesCompanion(potagerId: Value('p2')));

    await db.into(db.rappels).insert(RappelsCompanion.insert(
          id: 'r1',
          titre: 'Rappel',
          typeTacheGeneree: 'arrosage',
          dateDebut: now,
          typeRecurrence: 'ponctuel',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
          plantationId: const Value('pl1'),
        ));
    await db.into(db.observations).insert(ObservationsCompanion.insert(
          id: 'o1',
          dateObservation: now,
          type: 'general',
          titre: 'Observation',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
          parcelleId: const Value('pa1'),
        ));

    await repo.supprimer('p1');

    Future<String?> deletedAtTache(String id) async => (await (db.select(
                db.taches)
            ..where((t) => t.id.equals(id)))
        .getSingle())
        .deletedAt;

    // The whole p1 hierarchy and its planning rows are soft-deleted.
    for (final id in ['t_pot', 't_par', 't_pla', 't_eq']) {
      expect(await deletedAtTache(id), isNotNull, reason: 'tache $id');
    }
    expect(
        (await (db.select(db.rappels)..where((t) => t.id.equals('r1')))
                .getSingle())
            .deletedAt,
        isNotNull);
    expect(
        (await (db.select(db.observations)..where((t) => t.id.equals('o1')))
                .getSingle())
            .deletedAt,
        isNotNull);
    expect(
        (await (db.select(db.equipements)..where((t) => t.id.equals('eq1')))
                .getSingle())
            .deletedAt,
        isNotNull);

    // A task targeting another potager is untouched.
    expect(await deletedAtTache('t_other'), isNull);
  });
}
