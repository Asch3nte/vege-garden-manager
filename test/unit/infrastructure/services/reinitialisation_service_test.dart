import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/infrastructure/repositories/preferences_repository_impl.dart';
import 'package:pot_a_gerer/infrastructure/services/reinitialisation_service_impl.dart';

void main() {
  late AppDatabase db;
  late ReinitialisationServiceImpl service;
  late PreferencesRepositoryImpl prefs;
  final now = DateTime.utc(2026, 6, 5).toIso8601String();

  Future<void> insererPotager(String id) {
    return db.into(db.potagers).insert(PotagersCompanion.insert(
          id: id,
          nom: 'Jardin',
          climatType: 'oceanique',
          zoneRusticite: 'zone8',
          dateCreation: now,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<int> compter(String table) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.data['c'] as int;
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ReinitialisationServiceImpl(db);
    prefs = PreferencesRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('wipes all user data', () async {
    await insererPotager('pot1');
    await insererPotager('pot2');

    await service.reinitialiserTout();

    expect(await compter('potagers'), 0);
  });

  test('resets preferences to their defaults (first-run, re-onboarding)',
      () async {
    await prefs.sauvegarder(
      (await prefs.charger()).copierAvec(onboardingTermine: true),
    );

    await service.reinitialiserTout();

    // The singleton row is reseeded at its defaults.
    expect(await compter('preferences'), 1);
    final relu = await prefs.charger();
    expect(relu.onboardingTermine, isFalse);
  });
}
