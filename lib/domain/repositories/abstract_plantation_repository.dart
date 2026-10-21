import '../entities/plantation.dart';

/// Contract for persisting and retrieving plantations.
abstract class AbstractPlantationRepository {
  /// The plantation with this [id], or `null` when absent or soft-deleted.
  Future<Plantation?> obtenirParId(String id);
  Future<List<Plantation>> obtenirParParcelle(String parcelleId);
  Future<List<Plantation>> obtenirActives();
  Future<void> sauvegarder(Plantation plantation);
  Future<void> supprimer(String id);
}
