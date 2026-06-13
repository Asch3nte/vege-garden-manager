import '../../domain/repositories/abstract_reinitialisation_service.dart';
import '../database/app_database.dart';

/// drift-backed [AbstractReinitialisationService].
///
/// The wipe is **generic**: every table in [AppDatabase.allTables] is cleared in
/// a single transaction (children before parents to satisfy `ON DELETE RESTRICT`
/// foreign keys), then the preferences singleton is reseeded with its defaults —
/// mirroring the database's `onCreate` seed. After this the app is back to its
/// first-run state (`onboardingTermine == false`), so the router re-runs the
/// onboarding.
class ReinitialisationServiceImpl implements AbstractReinitialisationService {
  final AppDatabase _db;

  ReinitialisationServiceImpl(this._db);

  @override
  Future<void> reinitialiserTout() async {
    await _db.transaction(() async {
      for (final table in _db.allTables.toList().reversed) {
        await _db.customStatement('DELETE FROM ${table.actualTableName}');
      }
      // Reseed the singleton preferences row at its defaults (same as onCreate).
      await _db.into(_db.preferences).insert(
            PreferencesCompanion.insert(
              derniereModification: DateTime.now().toUtc().toIso8601String(),
            ),
          );
    });
  }
}
