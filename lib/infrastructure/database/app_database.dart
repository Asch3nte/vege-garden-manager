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
  int get schemaVersion => 6;

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
        // ⚠️ Any new/changed column MUST bump `schemaVersion` above AND add a
        // step here, else existing installs miss the column (docs/06 §5).
        onUpgrade: (m, from, to) async {
          // v1 → v2: onboarding-completion flag (defaults to false, so existing
          // installs are re-routed through the first-launch onboarding flow).
          if (from < 2) {
            await m.addColumn(preferences, preferences.onboardingTermine);
          }
          // v2 → v3: association weighting profile (ADR-0011); defaults to '{}'
          // (= the neutral profile), so existing installs keep working.
          if (from < 3) {
            await m.addColumn(preferences, preferences.ponderationAssociations);
          }
          // v3 → v4: ET₀ column for Open-Meteo data (ADR-0015 Lot 5).
          if (from < 4) {
            await m.addColumn(
                meteoCache, meteoCache.evapotranspirationMm);
          }
          // v4 → v5: active-garden selection (ADR-0009 multi-potager); null
          // default preserves the existing "earliest-created" fallback.
          if (from < 5) {
            await m.addColumn(preferences, preferences.potagerActifId);
          }
          // v5 → v6: auto weather-fetch opt-out (docs/11); defaults to true, so
          // existing installs keep fetching weather automatically as before.
          if (from < 6) {
            await m.addColumn(preferences, preferences.meteoAutoActive);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
