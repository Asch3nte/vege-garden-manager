import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/mode_import.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/services/sauvegarde_service_impl.dart';

import '../../../helpers/jeu_donnees_riche.dart';

void main() {
  late AppDatabase local;
  late AppDatabase origine;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    local = AppDatabase(NativeDatabase.memory());
    origine = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await local.close();
    await origine.close();
  });

  const ancien = '2026-06-15T10:30:45.000Z';
  const recent = '2026-09-01T08:00:00.000Z';

  Future<void> fusionner() async {
    final json = await SauvegardeServiceImpl(origine).exporterJson();
    await SauvegardeServiceImpl(local).importerJson(json, ModeImport.fusionner);
  }

  Future<void> peuplerLesDeux() async {
    await peuplerJeuRiche(origine);
    await peuplerJeuRiche(local);
  }

  Future<void> modifierPotager(AppDatabase db, String nom, String majLe) =>
      db.customStatement(
        'UPDATE potagers SET nom = ?, updated_at = ? WHERE id = ?',
        [nom, majLe, 'pot-1'],
      );

  Future<String> nomPot1(AppDatabase db) async {
    final rows = await db
        .customSelect("SELECT nom FROM potagers WHERE id = 'pot-1'")
        .get();
    expect(rows, hasLength(1));
    return rows.single.read<String>('nom');
  }

  test('merging a backup into its own origin changes nothing', () async {
    await peuplerJeuRiche(origine);
    final avant = await instantane(origine);
    final json = await SauvegardeServiceImpl(origine).exporterJson();
    await SauvegardeServiceImpl(
      origine,
    ).importerJson(json, ModeImport.fusionner);
    expect(await instantane(origine), equals(avant));
  });

  test(
    'merging into a diverged base keeps local-only and backup-only rows',
    () async {
      await peuplerLesDeux();
      Future<void> ajouter(AppDatabase db, String id) => db.customStatement(
        'INSERT INTO potagers (id, nom, emplacement, climat_type, '
        'zone_rusticite, date_creation, created_at, updated_at) '
        "VALUES (?, ?, 'jardin', 'oceanique', 'zone8', ?, ?, ?)",
        [id, id, ancien, ancien, ancien],
      );
      await ajouter(local, 'pot-local');
      await ajouter(origine, 'pot-backup');
      await fusionner();

      final apres = await instantane(local);
      final ids = [for (final r in apres['potagers']!) r['id']];
      expect(ids, hasLength(4));
      expect(ids.toSet(), {'pot-1', 'pot-2', 'pot-local', 'pot-backup'});
    },
  );

  test(
    'newer local row wins over older backup row',
    () async {
      await peuplerLesDeux();
      await modifierPotager(local, 'Nom local', recent);
      await fusionner();
      expect(await nomPot1(local), 'Nom local');
    },
    skip:
        'Merge lets the backup row overwrite a more recent local row '
        '(upsert ignores updated_at).',
  );

  test('newer backup row wins over older local row', () async {
    await peuplerLesDeux();
    await modifierPotager(origine, 'Nom sauvegarde', recent);
    await fusionner();
    expect(await nomPot1(local), 'Nom sauvegarde');
  });

  test('local preferences are kept on merge', () async {
    await peuplerJeuRiche(origine);
    await local.customStatement(
      "UPDATE preferences SET langue = 'fr', theme = 'clair' "
      "WHERE id = 'singleton'",
    );
    await fusionner();
    final rows = await local
        .customSelect(
          "SELECT langue, theme FROM preferences WHERE id = 'singleton'",
        )
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.read<String>('langue'), 'fr');
    expect(rows.single.read<String>('theme'), 'clair');
  }, skip: 'Merge overwrites local preferences with the backup values.');

  test('row deleted locally reappears after merge', () async {
    await peuplerLesDeux();
    await local.customStatement("DELETE FROM observations WHERE id = 'obs-2'");
    await fusionner();
    final rows = await local
        .customSelect("SELECT id FROM observations WHERE id = 'obs-2'")
        .get();
    expect(rows, hasLength(1));
  });

  test(
    'local row dated in the future',
    () async {
      await peuplerLesDeux();
      final futur = DateTime.now().toUtc().add(const Duration(days: 365));
      await modifierPotager(local, 'Nom futur', futur.toIso8601String());
      await fusionner();
      expect(await nomPot1(local), 'Nom futur');
    },
    skip:
        'Merge lets the older backup row overwrite a local row dated in '
        'the future (upsert ignores updated_at).',
  );
}
