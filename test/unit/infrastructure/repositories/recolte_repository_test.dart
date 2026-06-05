import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/recolte.dart';
import 'package:pot_a_gerer/domain/enums/destination_recolte.dart';
import 'package:pot_a_gerer/domain/enums/qualite_recolte.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/value_objects/quantite.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/recolte_repository_impl.dart';

void main() {
  late AppDatabase db;
  late RecolteRepositoryImpl repo;
  final now = DateTime.utc(2026, 7, 1).toIso8601String();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = RecolteRepositoryImpl(db);
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

  // Harvest dates must be in the past relative to the (real) row-creation clock
  // because of the CHECK (date_recolte <= date_creation).
  Recolte recolte({
    String id = 'r1',
    QualiteRecolte? qualite,
    DateTime? date,
  }) =>
      Recolte(
        id: id,
        plantationId: 'pl1',
        date: date ?? DateTime.utc(2026, 5, 20),
        quantite: const Quantite(2.5, UniteQuantite.kg),
        destination: DestinationRecolte.conservation,
        qualite: qualite,
      );

  test('round-trips quantity, destination and a null quality', () async {
    await repo.sauvegarder(recolte());
    final r = (await repo.obtenirParPlantation('pl1')).single;
    expect(r.quantite, const Quantite(2.5, UniteQuantite.kg));
    expect(r.destination, DestinationRecolte.conservation);
    expect(r.qualite, isNull);
  });

  test('round-trips an assessed quality', () async {
    await repo.sauvegarder(recolte(qualite: QualiteRecolte.excellente));
    expect((await repo.obtenirParPlantation('pl1')).single.qualite,
        QualiteRecolte.excellente);
  });

  test('obtenirParPlantation returns harvests ordered by date', () async {
    await repo.sauvegarder(recolte(id: 'b', date: DateTime.utc(2026, 5, 15)));
    await repo.sauvegarder(recolte(id: 'a', date: DateTime.utc(2026, 5, 10)));
    expect((await repo.obtenirParPlantation('pl1')).map((r) => r.id),
        ['a', 'b']);
  });
}
