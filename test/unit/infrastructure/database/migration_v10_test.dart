import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

import '../../../helpers/schemas_anciens.dart';

void main() {
  test('v9 → v10 copies the single units setting to every quantity', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(preferencesV9);
          raw.execute(parcellesV10);
          raw.execute(
            "INSERT INTO preferences (id, systeme_unites, "
            "derniere_modification) VALUES ('singleton', 'imperial', 'x')",
          );
          raw.execute('PRAGMA user_version = 9');
        },
      ),
    );
    addTearDown(db.close);

    // Raw read: the fixture holds only the columns the migration touches.
    final ligne =
        (await db
                .customSelect(
                  'SELECT unite_temperature, unite_longueur, '
                  'unite_surface, unite_volume, unite_masse FROM preferences',
                )
                .getSingle())
            .data;
    expect(ligne.values, everyElement('imperial'));
  });
}
