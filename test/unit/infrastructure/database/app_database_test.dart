import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 6, 1).toIso8601String();

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  PotagersCompanion potager(String id, {String emplacement = 'jardin'}) =>
      PotagersCompanion.insert(
        id: id,
        nom: 'Jardin',
        climatType: 'oceanique',
        dateCreation: now,
        createdAt: now,
        updatedAt: now,
        emplacement: Value(emplacement),
      );

  test('opens and seeds the preferences singleton', () async {
    final prefs = await db.select(db.preferences).getSingle();
    expect(prefs.id, 'singleton');
    expect(prefs.niveauExperience, 'debutant');
    expect(prefs.modeGeolocalisation, 'desactivee');
  });

  test('inserts and reads a potager', () async {
    await db.into(db.potagers).insert(potager('p1'));
    final rows = await db.select(db.potagers).get();
    expect(rows, hasLength(1));
    expect(rows.single.nom, 'Jardin');
  });

  test('enforces foreign keys (parcelle → unknown potager)', () async {
    await expectLater(
      db.into(db.parcelles).insert(
            ParcellesCompanion.insert(
              id: 'par1',
              nom: 'Planche',
              potagerId: 'inconnu',
              type: 'bacSureleve',
              surfaceValeur: 2,
              surfaceUnite: 'm2',
              exposition: 'pleinSoleil',
              positionOrdre: 0,
              dateCreation: now,
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('enforces a CHECK constraint (invalid emplacement)', () async {
    await expectLater(
      db.into(db.potagers).insert(potager('p2', emplacement: 'lune')),
      throwsA(isA<Exception>()),
    );
  });
}
