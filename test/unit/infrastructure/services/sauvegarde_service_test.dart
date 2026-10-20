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

  Map<String, dynamic> enveloppe(Map<String, dynamic> tables) =>
      {'schemaVersion': db.schemaVersion, 'tables': tables};

  test('rejects a row whose column is not in the table', () async {
    await insererPotager('pot1', 'Jardin');
    final backup = jsonDecode(await service.exporterJson())
        as Map<String, dynamic>;
    final ligne = ((backup['tables'] as Map<String, dynamic>)['potagers']
        as List)
        .single as Map<String, dynamic>;
    ligne['nom) VALUES (1); DROP TABLE potagers; --'] = 'x';

    await expectLater(
      service.importerJson(jsonEncode(backup), ModeImport.fusionner),
      throwsA(isA<SauvegardeInvalideException>()),
    );
    expect((await potagers()).single.nom, 'Jardin');
  });

  test('fusionner updates a parent row that has children', () async {
    await insererPotager('pot1', 'Jardin');
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
          updatedAt: now,
        ));
    final backup = await service.exporterJson();
    await (db.update(db.potagers)..where((t) => t.id.equals('pot1')))
        .write(const PotagersCompanion(nom: Value('Renommé')));

    await service.importerJson(backup, ModeImport.fusionner);

    expect((await potagers()).single.nom, 'Jardin');
    expect(await db.select(db.parcelles).get(), hasLength(1));
  });

  test('fusionner keeps the local row on a secondary unique key conflict',
      () async {
    MeteoCacheCompanion meteo(String id) => MeteoCacheCompanion.insert(
          id: id,
          latitude: 50,
          longitude: 4,
          date: '2026-06-05',
          type: 'prevu',
          dateRecuperation: now,
        );
    await db.into(db.meteoCache).insert(meteo('m1'));
    final backup = await service.exporterJson();
    await db.delete(db.meteoCache).go();
    await db.into(db.meteoCache).insert(meteo('m2'));

    await service.importerJson(backup, ModeImport.fusionner);

    expect((await db.select(db.meteoCache).get()).single.id, 'm2');
  });

  test('wraps a constraint violation in a typed exception', () async {
    final invalide = enveloppe({
      'potagers': [
        {'id': 'pot1', 'nom': 'Jardin'},
      ],
    });

    await expectLater(
      service.importerJson(jsonEncode(invalide), ModeImport.remplacer),
      throwsA(isA<SauvegardeInvalideException>()),
    );
  });

  test('rejects an empty row', () async {
    final invalide = enveloppe({
      'potagers': [<String, dynamic>{}],
    });

    await expectLater(
      service.importerJson(jsonEncode(invalide), ModeImport.fusionner),
      throwsA(isA<SauvegardeInvalideException>()),
    );
  });

  test('rejects a nested value', () async {
    await insererPotager('pot1', 'Jardin');
    final backup = jsonDecode(await service.exporterJson())
        as Map<String, dynamic>;
    (((backup['tables'] as Map<String, dynamic>)['potagers'] as List).single
        as Map<String, dynamic>)['nom'] = {'imbrique': true};

    await expectLater(
      service.importerJson(jsonEncode(backup), ModeImport.fusionner),
      throwsA(isA<SauvegardeInvalideException>()),
    );
  });
}
