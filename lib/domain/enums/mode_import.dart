/// How an imported backup is merged into the existing local data.
enum ModeImport {
  /// Wipe the existing data, then load the backup (full restore).
  remplacer,

  /// Keep the existing data and add/update rows from the backup (upsert by id).
  fusionner,
}
