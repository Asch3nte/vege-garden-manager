/// How an imported backup is merged into the existing local data.
///
/// See `docs/12-internationalisation-et-donnees.md` (import/restauration) and
/// `docs/11-parametres-et-opt-outs.md` §5.
enum ModeImport {
  /// Wipe the existing data, then load the backup (full restore).
  remplacer,

  /// Keep the existing data and add/update rows from the backup (upsert by id).
  fusionner,
}
