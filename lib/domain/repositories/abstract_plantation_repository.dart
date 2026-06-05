import '../entities/plantation.dart';

/// Contract for persisting and retrieving plantations.
///
/// See `docs/05-modele-de-domaine.md` §6.
abstract class AbstractPlantationRepository {
  Future<List<Plantation>> obtenirParParcelle(String parcelleId);
  Future<List<Plantation>> obtenirActives();
  Future<void> sauvegarder(Plantation plantation);
  Future<void> supprimer(String id);
}
