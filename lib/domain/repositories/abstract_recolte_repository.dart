import '../entities/recolte.dart';

/// Contract for persisting and retrieving harvests.
///
/// See `docs/05-modele-de-domaine.md` §6.
abstract class AbstractRecolteRepository {
  Future<List<Recolte>> obtenirParPlantation(String plantationId);
  Future<void> sauvegarder(Recolte recolte);
}
