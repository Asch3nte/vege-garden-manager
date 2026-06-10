import '../entities/potager.dart';

/// Contract for persisting and retrieving potagers. Implemented in the
/// infrastructure layer (dependency inversion).
///
/// See `docs/05-modele-de-domaine.md` §6.
abstract class AbstractPotagerRepository {
  /// The currently active potager, or `null` when none is selected.
  Future<Potager?> obtenirPotagerActif();

  /// All potagers.
  Future<List<Potager>> obtenirTous();

  /// Creates or updates [potager].
  Future<void> sauvegarder(Potager potager);

  /// Soft-deletes the garden [id] and, in cascade, its zones, their plantations,
  /// harvests and equipment (history preserved, rows filtered from reads).
  Future<void> supprimer(String id);
}
