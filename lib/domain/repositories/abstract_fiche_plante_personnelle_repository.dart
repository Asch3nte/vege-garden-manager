import '../entities/fiche_plante_personnelle.dart';

/// Contract for persisting and retrieving user-authored plant sheets.
///
/// Reads exclude soft-deleted rows. The on-disk source of truth is the emitted
/// YAML; implementations serialize on write and rebuild the model on read.
///
/// See `docs/05-modele-de-domaine.md` and `docs/07-base-de-connaissances-yaml.md`
/// §7.
abstract class AbstractFichePlantePersonnelleRepository {
  /// All personal sheets, most recently modified first.
  Future<List<FichePlantePersonnelle>> obtenirToutes();

  /// The personal sheet with this storage [id], or `null` if absent/deleted.
  Future<FichePlantePersonnelle?> obtenirParId(String id);

  /// The personal sheet exposed under the logical [idFiche], or `null`.
  Future<FichePlantePersonnelle?> obtenirParIdFiche(String idFiche);

  /// Raw `yaml_contenu` of every non-deleted sheet — the on-disk source of
  /// truth, fed as-is to the catalogue pipeline when merging personal sheets
  /// into the catalogue (a corrupt one is skipped there, never crashing).
  Future<List<String>> obtenirYamlBruts();

  /// Inserts or updates a sheet (upsert on storage [FichePlantePersonnelle.id]).
  Future<void> sauvegarder(FichePlantePersonnelle fiche);

  /// Soft-deletes the sheet (kept in the database, hidden from reads).
  Future<void> supprimer(String id);
}
