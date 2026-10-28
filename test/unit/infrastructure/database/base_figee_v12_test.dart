import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

import '../../../helpers/jeu_donnees_riche.dart';

void main() {
  test('v12 database opens with current schema without data loss', () async {
    final sql = File('test/fixtures/base_v12.sql').readAsStringSync();
    final attendu = jsonDecode(
      File('test/fixtures/base_v12_attendue.json').readAsStringSync(),
    );

    final db = AppDatabase(
      NativeDatabase.memory(setup: (raw) => raw.execute(sql)),
    );
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);

    final actuel =
        jsonDecode(jsonEncode(await instantane(db))) as Map<String, dynamic>;
    final gele = attendu as Map<String, dynamic>;
    for (final table in gele.keys) {
      final lignesActuelles = actuel[table] as List<dynamic>?;
      expect(lignesActuelles, isNotNull, reason: 'table $table missing');
      final lignesGelees = gele[table] as List<dynamic>;
      expect(
        lignesActuelles!.length,
        lignesGelees.length,
        reason: 'row count of $table',
      );
      for (var i = 0; i < lignesGelees.length; i++) {
        final gelee = lignesGelees[i] as Map<String, dynamic>;
        final ligne = lignesActuelles[i] as Map<String, dynamic>;
        for (final colonne in gelee.keys) {
          expect(
            ligne.containsKey(colonne),
            isTrue,
            reason: '$table[$i].$colonne missing',
          );
          expect(
            ligne[colonne],
            equals(gelee[colonne]),
            reason: '$table[$i].$colonne',
          );
        }
      }
    }
  });
}
