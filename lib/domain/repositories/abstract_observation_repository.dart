import '../entities/observation.dart';
import '../enums/cible_observation.dart';

/// Contract for persisting and retrieving journal observations.
///
/// See `docs/05-modele-de-domaine.md` §6 (ADR-0004 D6).
abstract class AbstractObservationRepository {
  Future<List<Observation>> obtenirParCible(
    CibleObservation cible,
    String cibleId,
  );
  Future<List<Observation>> obtenirNonResolues();
  Future<void> sauvegarder(Observation observation);
  Future<void> supprimer(String id);
}
