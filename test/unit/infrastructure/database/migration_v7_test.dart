import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';

import '../../../helpers/schemas_anciens.dart';

/// `taches` as created by schema version 6.
const _tachesV6 = 'CREATE TABLE "taches" ("id" TEXT NOT NULL, "titre" TEXT NOT NULL, '
    '"description" TEXT NULL, "type" TEXT NOT NULL, "etat" TEXT NOT NULL DEFAULT \'aFaire\', '
    '"priorite" TEXT NOT NULL DEFAULT \'normale\', "potager_id" TEXT NULL, '
    '"parcelle_id" TEXT NULL, "plantation_id" TEXT NULL, "equipement_id" TEXT NULL, '
    '"date_prevue" TEXT NOT NULL, "date_realisation" TEXT NULL, '
    '"duree_reelle_minutes" INTEGER NULL, "rappel_origine_id" TEXT NULL, '
    '"date_creation" TEXT NOT NULL, "notes" TEXT NULL, "created_at" TEXT NOT NULL, '
    '"updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, '
    '"sync_version" INTEGER NOT NULL DEFAULT 1, PRIMARY KEY ("id"))';

/// The `parcelles` columns later migrations touch, as of schema version 6.
const _parcellesV6 = 'CREATE TABLE "parcelles" ("id" TEXT NOT NULL, '
    '"potager_id" TEXT NOT NULL, "position_ordre" INTEGER NOT NULL, '
    '"created_at" TEXT NOT NULL DEFAULT \'x\', "deleted_at" TEXT NULL, '
    'PRIMARY KEY ("id"))';

void main() {
  test('v6 → v7 turns the engine watering titles into derived ones', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(_tachesV6);
      raw.execute(_parcellesV6);
      raw.execute(preferencesV9);
      void inserer(String id, String titre, String type, String? plantationId) =>
          raw.execute(
              'INSERT INTO taches (id, titre, type, potager_id, plantation_id, '
              'date_prevue, date_creation, created_at, updated_at) '
              "VALUES (?, ?, ?, ?, ?, '2026-06-01', 'x', 'x', 'x')",
              [id, titre, type, plantationId == null ? 'p1' : null, plantationId]);
      inserer('a', 'Arroser : Tomate', 'arrosage', 'pl1');
      inserer('b', 'Arroser', 'arrosage', 'pl2');
      inserer('c', 'Arroser le compost', 'arrosage', 'pl3');
      inserer('d', 'Arroser : Tomate', 'arrosage', null);
      inserer('e', 'Arroser : Tomate', 'desherbage', 'pl4');
      raw.execute('PRAGMA user_version = 6');
    }));
    addTearDown(db.close);

    final lignes = {
      for (final r in await db.select(db.taches).get()) r.id: r,
    };
    expect(lignes['a']!.titre, isNull);
    expect(lignes['a']!.generee, isTrue);
    expect(lignes['b']!.titre, isNull);
    expect(lignes['b']!.generee, isTrue);
    for (final id in ['c', 'd', 'e']) {
      expect(lignes[id]!.titre, isNotNull, reason: id);
      expect(lignes[id]!.generee, isFalse, reason: id);
    }
  });
}
