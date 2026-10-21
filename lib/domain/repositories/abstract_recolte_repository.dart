import '../entities/recolte.dart';

/// Contract for persisting and retrieving harvests.
abstract class AbstractRecolteRepository {
  Future<List<Recolte>> obtenirParPlantation(String plantationId);
  Future<void> sauvegarder(Recolte recolte);
}
