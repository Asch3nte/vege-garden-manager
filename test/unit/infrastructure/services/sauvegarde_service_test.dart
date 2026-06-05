import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/mode_import.dart';
import 'package:pot_a_gerer/domain/exceptions/sauvegarde_invalide_exception.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/services/sauvegarde_service_impl.dart';

void main() {
  late AppDatabase db;
  late SauvegardeServiceImpl service;
  final now = DateTime.utc(2026, 6, 5).toIso8601String();

  Future<void> insererPotager(String id, String nom) {
    return db.into(db.potagers).insert(PotagersCompanion.insert(
          id: id,
          nom: nom,
          climatType: 'oceanique',
          zoneRusticite: 'zone8',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<List<PotagerRow>> potagers() => db.select(db.potagers).get();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = SauvegardeServiceImpl(db);
  });
  tearDown(() => db.close());

  test('export produces a versioned envelope with every table', () async {
    await insererPotager('pot1', 'Jardin');

    final json = jsonDecode(await service.exporterJson()) as Map<String, dynamic>;

    expect(json['schemaVersion'], db.schemaVersion);
    final tables = json['tables'] as Map<String, dynamic>;
    expect(tables.keys, contains('potagers'));
    expect(tables.keys, contains('preferences')); // seeded singleton
    expect((tables['potagers'] as List).single['nom'], 'Jardin');
  });

  test('remplacer wipes current data and restores the backup', () async {
    await insererPotager('pot1', 'Jardin');
    final backup = await service.exporterJson();

    await insererPotager('pot2', 'Balcon'); // diverge from the backup

    await service.importerJson(backup, ModeImport.remplacer);

    final result = await potagers();
    expect(result, hasLength(1));
    expect(result.single.id, 'pot1');
  });

  test('fusionner keeps current rows and re-adds missing ones', () async {
    await insererPotager('pot1', 'Jardin');
    await insererPotager('pot2', 'Balcon');
    final backup = await service.exporterJson();

    // Delete pot2, then merge the backup: pot1 stays, pot2 comes back.
    await (db.delete(db.potagers)..where((t) => t.id.equals('pot2'))).go();

    await service.importerJson(backup, ModeImport.fusionner);

    final ids = (await potagers()).map((p) => p.id).toSet();
    expect(ids, {'pot1', 'pot2'});
  });

  test('fusionner overwrites an existing row by id', () async {
    await insererPotager('pot1', 'Jardin');
    final backup = await service.exporterJson();

    await (db.update(db.potagers)..where((t) => t.id.equals('pot1')))
        .write(const PotagersCompanion(nom: Value('Renommé')));

    await service.importerJson(backup, ModeImport.fusionner);

    expect((await potagers()).single.nom, 'Jardin');
  });

  test('rejects malformed JSON', () async {
    expect(
      () => service.importerJson('not json', ModeImport.remplacer),
      throwsA(isA<SauvegardeInvalideException>()),
    );
  });

  test('rejects an unsupported schema version', () async {
    final badVersion = jsonEncode({'schemaVersion': 999, 'tables': {}});
    expect(
      () => service.importerJson(badVersion, ModeImport.remplacer),
      throwsA(isA<SauvegardeInvalideException>()),
    );
  });
}
