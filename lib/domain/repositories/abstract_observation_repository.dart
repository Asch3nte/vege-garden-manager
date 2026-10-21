import '../entities/observation.dart';
import '../enums/cible_observation.dart';

/// Contract for persisting and retrieving journal observations.
abstract class AbstractObservationRepository {
  Future<List<Observation>> obtenirParCible(
    CibleObservation cible,
    String cibleId,
  );
  Future<List<Observation>> obtenirNonResolues();
  Future<void> sauvegarder(Observation observation);
  Future<void> supprimer(String id);
}
