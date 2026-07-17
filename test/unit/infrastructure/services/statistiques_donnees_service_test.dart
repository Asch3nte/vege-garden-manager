import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/services/statistiques_donnees_service_impl.dart';

void main() {
  late AppDatabase db;
  late StatistiquesDonneesServiceImpl service;
  final now = DateTime.utc(2026, 6, 5).toIso8601String();

  Future<void> insererPotager(String id) {
    return db.into(db.potagers).insert(PotagersCompanion.insert(
          id: id,
          nom: 'Jardin',
          climatType: 'oceanique',
          zoneRusticite: 'zone8',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = StatistiquesDonneesServiceImpl(db);
  });
  tearDown(() => db.close());

  test('counts records per table and reports a positive on-disk size',
      () async {
    await insererPotager('p1');
    await insererPotager('p2');

    final stats = await service.obtenirStatistiques();

    final potagers = stats.tables.firstWhere((t) => t.nom == 'potagers');
    expect(potagers.lignes, 2);
    // Every schema table is listed (generic read over allTables).
    expect(stats.tables.length, db.allTables.length);
    expect(stats.tailleOctets, greaterThan(0));
    // Total spans every table (includes the seeded preferences singleton).
    expect(stats.totalLignes, greaterThanOrEqualTo(2));
  });

  test('lists tables sorted by name', () async {
    final stats = await service.obtenirStatistiques();
    final noms = stats.tables.map((t) => t.nom).toList();
    expect(noms, equals([...noms]..sort()));
  });

  test('an empty user table reports zero', () async {
    final stats = await service.obtenirStatistiques();
    final potagers = stats.tables.firstWhere((t) => t.nom == 'potagers');
    expect(potagers.lignes, 0);
  });
}
