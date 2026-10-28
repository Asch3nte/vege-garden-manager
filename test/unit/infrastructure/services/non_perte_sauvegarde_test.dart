import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/mode_import.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/services/reinitialisation_service_impl.dart';
import 'package:pot_a_gerer/infrastructure/services/sauvegarde_service_impl.dart';

import '../../../helpers/jeu_donnees_riche.dart';

void main() {
  late AppDatabase a;
  late AppDatabase b;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    a = AppDatabase(NativeDatabase.memory());
    b = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  Future<void> verifierAllerRetour(
    String json,
    Map<String, List<Map<String, Object?>>> avant,
  ) async {
    await ReinitialisationServiceImpl(a).reinitialiserTout();
    await SauvegardeServiceImpl(a).importerJson(json, ModeImport.remplacer);
    expect(await instantane(a), equals(avant));

    await SauvegardeServiceImpl(b).importerJson(json, ModeImport.remplacer);
    expect(await instantane(b), equals(avant));
  }

  test('replace round-trip restores every table field by field', () async {
    await peuplerJeuRiche(a);
    final json = await SauvegardeServiceImpl(a).exporterJson();
    final avant = await instantane(a);
    for (final e in avant.entries) {
      expect(e.value, isNotEmpty, reason: e.key);
    }
    await verifierAllerRetour(json, avant);
  });

  test('creation dates survive the round-trip', () async {
    await peuplerJeuRiche(a);
    final json = await SauvegardeServiceImpl(a).exporterJson();
    final avant = await instantane(a);
    await SauvegardeServiceImpl(b).importerJson(json, ModeImport.remplacer);
    final apres = await instantane(b);

    const colonnes = ['created_at', 'date_creation'];
    var verifiees = 0;
    for (final entry in avant.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        for (final c in colonnes) {
          if (!entry.value[i].containsKey(c)) continue;
          verifiees++;
          expect(
            apres[entry.key]![i][c],
            entry.value[i][c],
            reason: '${entry.key}[$i].$c',
          );
          expect(entry.value[i][c], isNotNull);
        }
      }
    }
    expect(verifiees, greaterThan(20));
    for (final table in ['potagers', 'parcelles', 'taches', 'rappels']) {
      expect(
        apres[table]!.first['created_at'],
        isNot(apres[table]!.first['updated_at']),
        reason: table,
      );
    }
  });

  test('large backup round-trips', () async {
    await peuplerJeuRiche(a, nbTachesSupplementaires: 5000);
    final json = await SauvegardeServiceImpl(a).exporterJson();
    final avant = await instantane(a);
    expect(avant['taches']!.length, greaterThan(5000));
    await verifierAllerRetour(json, avant);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
