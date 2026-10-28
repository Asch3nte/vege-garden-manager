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

    expect(jsonDecode(jsonEncode(await instantane(db))), equals(attendu));
  });
}
