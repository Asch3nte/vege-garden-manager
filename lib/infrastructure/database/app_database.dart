import 'package:drift/drift.dart';

import 'tables.dart';
import 'teintes_zone_v8.dart';

part 'app_database.g.dart';

/// The application's local SQLite database (drift).
///
/// Foreign keys are
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
    Favoris,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 9;

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
        // step here, else existing installs miss the column.
        // Data reshaped by a step must be reshaped the same way in
        // MonteeSauvegarde, or older backups import in the old shape.
        onUpgrade: (m, from, to) async {
          // v1 → v2: onboarding-completion flag (defaults to false, so existing
          // installs are re-routed through the first-launch onboarding flow).
          if (from < 2) {
            await m.addColumn(preferences, preferences.onboardingTermine);
          }
          // v2 → v3: association weighting profile; defaults to '{}'
          // (= the neutral profile), so existing installs keep working.
          if (from < 3) {
            await m.addColumn(preferences, preferences.ponderationAssociations);
          }
          // v3 → v4: ET₀ column for Open-Meteo data.
          if (from < 4) {
            await m.addColumn(
                meteoCache, meteoCache.evapotranspirationMm);
          }
          // v4 → v5: active-garden selection; null
          // default preserves the existing "earliest-created" fallback.
          if (from < 5) {
            await m.addColumn(preferences, preferences.potagerActifId);
          }
          // v5 → v6: auto weather-fetch opt-out; defaults to true, so
          // existing installs keep fetching weather automatically as before.
          if (from < 6) {
            await m.addColumn(preferences, preferences.meteoAutoActive);
          }
          // v6 → v7: engine-maintained tasks, whose title is derived from the
          // type and target; the engine's former French watering titles are
          // dropped so they follow the language.
          if (from < 7) {
            await m.alterTable(
                TableMigration(taches, newColumns: [taches.generee]));
            await customStatement(
                "UPDATE taches SET generee = 1, titre = NULL "
                "WHERE type = 'arrosage' AND plantation_id IS NOT NULL "
                "AND (titre = 'Arroser' OR titre LIKE 'Arroser : %')");
          }
          // v7 → v8: stored zone colour; each zone keeps the tint it showed
          // by its position among its garden's zones.
          if (from < 8) {
            await m.addColumn(parcelles, parcelles.couleurTeinte);
            await m.addColumn(parcelles, parcelles.couleurRgb);
            const teintes = teintesZoneV8;
            final cas = [
              for (var i = 0; i < teintes.length; i++)
                "WHEN $i THEN '${teintes[i]}'",
            ].join(' ');
            await customStatement(
                'UPDATE parcelles SET couleur_teinte = ('
                'SELECT CASE (r.rang - 1) % ${teintes.length} $cas END '
                'FROM (SELECT id, ROW_NUMBER() OVER ('
                'PARTITION BY potager_id '
                'ORDER BY position_ordre, created_at, rowid) AS rang '
                'FROM parcelles WHERE deleted_at IS NULL) r '
                'WHERE r.id = parcelles.id)');
          }
          // v8 → v9: favourite plant sheets.
          if (from < 9) {
            await m.createTable(favoris);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
