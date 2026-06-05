import '../entities/equipement.dart';

/// Contract for persisting and retrieving equipment.
///
/// Reads exclude soft-deleted rows. Retiring equipment (recording a
/// `dateRetrait`) is a domain operation on the entity, distinct from
/// [supprimer] (which soft-deletes the record entirely).
///
/// See `docs/05-modele-de-domaine.md` §6.
abstract class AbstractEquipementRepository {
  /// All equipment of a potager (including the transverse ones, parcelle-less).
  Future<List<Equipement>> obtenirParPotager(String potagerId);

  /// Equipment attached to a specific parcelle.
  Future<List<Equipement>> obtenirParParcelle(String parcelleId);

  Future<Equipement?> obtenirParId(String id);
  Future<void> sauvegarder(Equipement equipement);

  /// Soft-deletes the equipment (kept in the database, hidden from reads).
  Future<void> supprimer(String id);
}
