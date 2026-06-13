import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The application's local SQLite database (drift).
///
/// Schema reference: `docs/06-modele-de-donnees-sqlite.md`. Foreign keys are
/// enforced (`PRAGMA foreign_keys = ON`) and use `ON DELETE RESTRICT`; deletions
/// cascade *logically* in the repositories (soft-delete strategy).
@DriftDatabase(
  tables: [
    Potagers,
    Parcelles,
    Plantations,
    Recoltes,
    Equipements,
    Taches,
    Rappels,
    Observations,
    MeteoCache,
    Parametres,
    FichesPlantesPersonnelles,
    Preferences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed the singleton preferences row.
          await into(preferences).insert(
            PreferencesCompanion.insert(
              derniereModification: DateTime.now().toUtc().toIso8601String(),
            ),
          );
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: onboarding-completion flag (defaults to false, so existing
          // installs are re-routed through the first-launch onboarding flow).
          if (from < 2) {
            await m.addColumn(preferences, preferences.onboardingTermine);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
