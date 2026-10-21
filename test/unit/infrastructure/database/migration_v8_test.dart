import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

import '../../../helpers/schemas_anciens.dart';

/// `parcelles` as created by schema version 7.
const _parcellesV7 =
    'CREATE TABLE "parcelles" ("id" TEXT NOT NULL, '
    '"nom" TEXT NOT NULL, "potager_id" TEXT NOT NULL, "type" TEXT NOT NULL, '
    '"surface_valeur" REAL NOT NULL, "surface_unite" TEXT NOT NULL, '
    '"exposition" TEXT NOT NULL, "texture_sol" TEXT NULL, "ph_sol" TEXT NULL, '
    '"texture_sol_source" TEXT NOT NULL DEFAULT \'manuelle\', '
    '"techniques_sol" TEXT NULL, '
    '"culture_verticale" INTEGER NOT NULL DEFAULT 0, '
    '"position_ordre" INTEGER NOT NULL, "position_x" REAL NULL, '
    '"position_y" REAL NULL, "position_largeur" REAL NULL, '
    '"position_hauteur" REAL NULL, "position_rotation" REAL NULL, '
    '"date_creation" TEXT NOT NULL, "notes" TEXT NULL, '
    '"created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, '
    '"deleted_at" TEXT NULL, "sync_version" INTEGER NOT NULL DEFAULT 1, '
    'PRIMARY KEY ("id"))';

void main() {
  test('v7 → v8 gives each zone the colour it showed by position', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(_parcellesV7);
      raw.execute(preferencesV9);
          void inserer(
            String id,
            String potager,
            int ordre, {
            bool supprimee = false,
          }) => raw.execute(
            'INSERT INTO parcelles (id, nom, potager_id, type, surface_valeur, '
            'surface_unite, exposition, position_ordre, date_creation, '
            'created_at, updated_at, deleted_at) '
            "VALUES (?, ?, ?, 'pot', 1, 'm2', 'pleinSoleil', ?, 'x', 'x', 'x', ?)",
            [id, id, potager, ordre, supprimee ? 'x' : null],
          );
          // Displayed order: position, then insertion order on ties.
          inserer('b', 'pot1', 1);
          inserer('a', 'pot1', 0);
          inserer('s', 'pot1', 0, supprimee: true);
          inserer('c', 'pot1', 1);
          inserer('z', 'pot2', 0);
          for (var i = 0; i < 6; i++) {
            inserer('n$i', 'pot3', i);
          }
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );
    addTearDown(db.close);

    final lignes = {
      for (final r in await db.select(db.parcelles).get()) r.id: r,
    };
    expect(lignes['a']!.couleurTeinte, 'vertProfond');
    expect(lignes['b']!.couleurTeinte, 'terracotta');
    expect(lignes['c']!.couleurTeinte, 'aubergine');
    expect(lignes['z']!.couleurTeinte, 'vertProfond');
    expect(
      [for (var i = 0; i < 6; i++) lignes['n$i']!.couleurTeinte],
      [
        'vertProfond',
        'terracotta',
        'aubergine',
        'vertMoyen',
        'bordeaux',
        'terre',
      ],
    );
    expect(lignes.values.map((r) => r.couleurRgb), everyElement(isNull));
  });
}
