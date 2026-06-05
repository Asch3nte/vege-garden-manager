import '../entities/parcelle.dart';

/// Contract for persisting and retrieving parcelles.
///
/// See `docs/05-modele-de-domaine.md` §6.
abstract class AbstractParcelleRepository {
  Future<List<Parcelle>> obtenirParPotager(String potagerId);
  Future<Parcelle?> obtenirParId(String id);
  Future<void> sauvegarder(Parcelle parcelle);
  Future<void> supprimer(String id);
}
