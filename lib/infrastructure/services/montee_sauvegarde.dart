/// Brings the tables of a backup from an older schema version to the current
/// one, mirroring the database migrations.
///
/// Columns added since are left out of the rows and take their default; only
/// data reshaped by a migration is rewritten here.
class MonteeSauvegarde {
  const MonteeSauvegarde();

  /// Rewrites [tables] in place from schema version [depuis].
  void monter(Map<String, dynamic> tables, int depuis) {
    if (depuis < 7) _versV7(tables);
  }

  /// The engine's French watering titles become derived ones.
  void _versV7(Map<String, dynamic> tables) {
    final taches = tables['taches'];
    if (taches is! List) return;
    for (final ligne in taches.whereType<Map<String, dynamic>>()) {
      final titre = ligne['titre'];
      if (ligne['type'] == 'arrosage' &&
          ligne['plantation_id'] != null &&
          (titre == 'Arroser' ||
              (titre is String && titre.startsWith('Arroser : ')))) {
        ligne['titre'] = null;
        ligne['generee'] = 1;
      }
    }
  }
}
