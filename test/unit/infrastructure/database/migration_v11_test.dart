import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

import '../../../helpers/schemas_anciens.dart';

void main() {
  test('v10 → v11 adds unknown dimensions and water need to zones', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(preferencesV9);
          raw.execute(parcellesV10);
          raw.execute(
            "INSERT INTO parcelles (id, surface_valeur) VALUES ('par1', 4)",
          );
          raw.execute('PRAGMA user_version = 10');
        },
      ),
    );
    addTearDown(db.close);

    // Raw read: the fixture holds only the columns the migration touches.
    final ligne =
        (await db
                .customSelect(
                  'SELECT surface_valeur, longueur_cm, largeur_cm, besoin_eau '
                  'FROM parcelles',
                )
                .getSingle())
            .data;
    expect(ligne, {
      'surface_valeur': 4.0,
      'longueur_cm': null,
      'largeur_cm': null,
      'besoin_eau': null,
    });
  });
}
