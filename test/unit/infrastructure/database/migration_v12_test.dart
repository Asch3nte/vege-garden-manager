import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

import '../../../helpers/schemas_anciens.dart';

void main() {
  test('v11 → v12 keeps confirming deletions', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(preferencesV9);
          raw.execute(
            "INSERT INTO preferences (derniere_modification) VALUES ('t')",
          );
          raw.execute('PRAGMA user_version = 11');
        },
      ),
    );
    addTearDown(db.close);

    // Raw read: the fixture holds only the columns the migration touches.
    final ligne = (await db
            .customSelect('SELECT confirmer_suppressions FROM preferences')
            .getSingle())
        .data;
    expect(ligne, {'confirmer_suppressions': 1});
  });
}
