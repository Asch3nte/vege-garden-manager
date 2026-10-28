import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/mode_import.dart';
import 'package:pot_a_gerer/domain/exceptions/sauvegarde_invalide_exception.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/services/sauvegarde_service_impl.dart';

import '../../../helpers/jeu_donnees_riche.dart';

void main() {
  late AppDatabase db;
  late SauvegardeServiceImpl service;
  late Map<String, dynamic> valide;
  late Map<String, List<Map<String, Object?>>> avant;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    service = SauvegardeServiceImpl(db);
    await peuplerJeuRiche(db);
    valide = jsonDecode(await service.exporterJson()) as Map<String, dynamic>;
    avant = await instantane(db);
  });
  tearDown(() => db.close());

  Map<String, dynamic> copie() =>
      jsonDecode(jsonEncode(valide)) as Map<String, dynamic>;

  List<dynamic> lignes(Map<String, dynamic> doc, String table) =>
      (doc['tables'] as Map<String, dynamic>)[table] as List<dynamic>;

  Future<void> refuse(Object contenu) async {
    final json = contenu is String ? contenu : jsonEncode(contenu);
    for (final mode in ModeImport.values) {
      await expectLater(
        service.importerJson(json, mode),
        throwsA(isA<SauvegardeInvalideException>()),
        reason: mode.name,
      );
      expect(await instantane(db), equals(avant), reason: mode.name);
    }
  }

  test('truncated JSON is refused', () async {
    final json = jsonEncode(valide);
    await refuse(json.substring(0, json.length ~/ 2));
  });

  test('non-JSON text is refused', () => refuse('not a backup at all'));

  test('JSON that is not an object is refused', () => refuse('[1, 2, 3]'));

  test('newer schemaVersion is refused', () async {
    final doc = copie()..['schemaVersion'] = db.schemaVersion + 1;
    await refuse(doc);
  });

  test('missing schemaVersion is refused', () async {
    final doc = copie()..remove('schemaVersion');
    await refuse(doc);
  });

  test('missing tables is refused', () async {
    final doc = copie()..remove('tables');
    await refuse(doc);
  });

  test('unknown column is refused', () async {
    final doc = copie();
    (lignes(doc, 'potagers').first
            as Map<String, dynamic>)['colonne_inconnue'] =
        'x';
    await refuse(doc);
  });

  test('object value is refused', () async {
    final doc = copie();
    (lignes(doc, 'potagers').first as Map<String, dynamic>)['nom'] = {'a': 1};
    await refuse(doc);
  });

  test('list value is refused', () async {
    final doc = copie();
    (lignes(doc, 'potagers').first as Map<String, dynamic>)['nom'] = [1, 2];
    await refuse(doc);
  });

  test('empty row is refused', () async {
    final doc = copie();
    lignes(doc, 'potagers').add(<String, dynamic>{});
    await refuse(doc);
  });

  test('non-object row is refused', () async {
    final doc = copie();
    lignes(doc, 'potagers').add('oops');
    await refuse(doc);
  });

  test('row pointing to a missing parent is refused', () async {
    final doc = copie();
    final orpheline =
        Map<String, dynamic>.from(lignes(doc, 'parcelles').first as Map)
          ..['id'] = 'parcelle-orpheline'
          ..['potager_id'] = 'potager-absent';
    lignes(doc, 'parcelles').add(orpheline);
    await refuse(doc);
  });

  test(
    'failure on the last row of the last table rolls everything back',
    () async {
      final doc = copie();
      final tables = doc['tables'] as Map<String, dynamic>;
      final derniere = db.allTables
          .map((t) => t.actualTableName)
          .lastWhere((n) => (tables[n] as List?)?.isNotEmpty ?? false);
      final mauvaise = Map<String, dynamic>.from(
        lignes(doc, derniere).last as Map,
      )..['colonne_inconnue'] = 'x';
      lignes(doc, derniere).add(mauvaise);
      await refuse(doc);
    },
  );

  test('unknown table is ignored and the rest is imported', () async {
    final doc = copie();
    (doc['tables'] as Map<String, dynamic>)['table_inconnue'] = [
      {'a': 1},
    ];
    await db.customStatement("UPDATE potagers SET nom = 'modifie'");
    expect(await instantane(db), isNot(equals(avant)));

    await service.importerJson(jsonEncode(doc), ModeImport.remplacer);
    expect(await instantane(db), equals(avant));
  });
}
