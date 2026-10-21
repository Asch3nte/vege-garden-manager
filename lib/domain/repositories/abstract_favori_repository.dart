/// Contract for the user's favourite plant sheets, keyed by sheet id.
///
/// Reads exclude soft-deleted rows.
abstract class AbstractFavoriRepository {
  /// Ids of the favourite sheets.
  Future<Set<String>> obtenirIds();

  /// Marks [ficheId] as favourite (no-op if it already is).
  Future<void> ajouter(String ficheId);

  /// Soft-deletes the favourite [ficheId] (no-op if absent).
  Future<void> retirer(String ficheId);
}
