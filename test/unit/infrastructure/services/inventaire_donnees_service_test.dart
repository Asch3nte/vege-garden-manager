import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/services/inventaire_donnees_service_impl.dart';

void main() {
  late AppDatabase db;
  late InventaireDonneesServiceImpl service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = InventaireDonneesServiceImpl(db);
  });
  tearDown(() => db.close());

  test('counts every table, and the preferences singleton is seeded to 1',
      () async {
    final inventaire = await service.obtenir();

    // Every stored table appears (nothing hidden), same set as the reset walk.
    final noms = inventaire.entrees.map((e) => e.table).toSet();
    expect(noms, containsAll(<String>{'potagers', 'plantations', 'preferences'}));
    // Fresh DB: only the preferences singleton is seeded (onCreate).
    final prefs = inventaire.entrees.firstWhere((e) => e.table == 'preferences');
    expect(prefs.nombre, 1);
    final potagers = inventaire.entrees.firstWhere((e) => e.table == 'potagers');
    expect(potagers.nombre, 0);
  });

  test('reflects inserted rows in the counts and the total', () async {
    final stamp = DateTime(2026, 1, 1).toIso8601String();
    await db.into(db.potagers).insert(PotagersCompanion.insert(
          id: 'pot-1',
          nom: 'Mon potager',
          climatType: 'oceanique',
          zoneRusticite: 'zone8',
          dateCreation: stamp,
          createdAt: stamp,
          updatedAt: stamp,
        ));

    final inventaire = await service.obtenir();

    final potagers = inventaire.entrees.firstWhere((e) => e.table == 'potagers');
    expect(potagers.nombre, 1);
    // Total = the potager + the seeded preferences singleton.
    expect(inventaire.total, greaterThanOrEqualTo(2));
  });
}
