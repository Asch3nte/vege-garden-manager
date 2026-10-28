// Freezes the current database schema and the rich sample data as test fixtures.
//
// Usage (pure Dart, needs the system sqlite3 library):
//   dart run tool/figer_base.dart <version>
// Writes test/fixtures/base_v<version>.sql (schema, data and user_version) and
// test/fixtures/base_v<version>_attendue.json (snapshot of the data). The
// version must equal AppDatabase.schemaVersion. Output is deterministic.
//
// Run it once per released schema, then commit the files and never regenerate
// them: they stand for databases already in users' hands.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

import '../test/helpers/jeu_donnees_riche.dart';

String _litteral(Object? v) {
  if (v == null) return 'NULL';
  if (v is num) return v.toString();
  if (v is Uint8List) {
    return "X'${v.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'";
  }
  return "'${v.toString().replaceAll("'", "''")}'";
}

Future<void> main(List<String> args) async {
  if (args.length != 1 || int.tryParse(args.single) == null) {
    stderr.writeln('Usage: dart run tool/figer_base.dart <version>');
    exitCode = 64;
    return;
  }
  final version = int.parse(args.single);
  final db = AppDatabase(NativeDatabase.memory());
  try {
    if (version != db.schemaVersion) {
      stderr.writeln(
        'Version $version differs from schemaVersion ${db.schemaVersion}.',
      );
      exitCode = 1;
      return;
    }
    await peuplerJeuRiche(db, horodatage: DateTime.utc(2026, 6, 1));
    final snapshot = await instantane(db);

    final sql = StringBuffer();
    final objets = await db
        .customSelect(
          'SELECT sql FROM sqlite_master WHERE sql IS NOT NULL '
          "AND name NOT LIKE 'sqlite_%' "
          "ORDER BY CASE type WHEN 'table' THEN 0 ELSE 1 END, name",
        )
        .get();
    for (final o in objets) {
      sql.writeln('${o.read<String>('sql')};');
    }
    final tables = snapshot.keys.toList()..sort();
    for (final t in tables) {
      for (final ligne in snapshot[t]!) {
        final cols = ligne.keys.map((c) => '"$c"').join(', ');
        final vals = ligne.values.map(_litteral).join(', ');
        sql.writeln('INSERT INTO "$t" ($cols) VALUES ($vals);');
      }
    }
    sql.writeln('PRAGMA user_version = $version;');

    final json = const JsonEncoder.withIndent('  ').convert(snapshot);
    File('test/fixtures/base_v$version.sql').writeAsStringSync(sql.toString());
    File(
      'test/fixtures/base_v${version}_attendue.json',
    ).writeAsStringSync('$json\n');
    stdout.writeln('Wrote test/fixtures/base_v$version.*');
  } finally {
    await db.close();
  }
}
