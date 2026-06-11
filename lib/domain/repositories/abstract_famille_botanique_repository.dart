import '../entities/famille_botanique.dart';
import '../enums/categorie_plante.dart';

/// Contract for reading the botanical-family reference (loaded from YAML, never
/// written by the user through this contract).
///
/// Families are a sibling type of the plant catalogue (ADR-0006): they drive the
/// catalogue family filter and carry family-level educational content.
abstract class AbstractFamilleBotaniqueRepository {
  /// Every loaded family (unordered).
  Future<List<FamilleBotanique>> obtenirToutes();

  /// Family with [id] (the normalized scientific name), or `null` if absent.
  Future<FamilleBotanique?> obtenirParId(String id);

  /// Families declared relevant to [categorie] (`estPertinentePour`).
  Future<List<FamilleBotanique>> filtrerParCategorie(CategoriePlante categorie);
}
