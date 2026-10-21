import '../entities/parcelle.dart';

/// Contract for persisting and retrieving parcelles.
abstract class AbstractParcelleRepository {
  Future<List<Parcelle>> obtenirParPotager(String potagerId);
  Future<Parcelle?> obtenirParId(String id);
  Future<void> sauvegarder(Parcelle parcelle);
  Future<void> supprimer(String id);
}
