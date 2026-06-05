import '../entities/rappel.dart';
import '../enums/cible_tache.dart';

/// Contract for persisting and retrieving reminders (the rules that generate
/// tasks).
///
/// Reads exclude soft-deleted rows. A reminder targets exactly one of a
/// potager, parcelle, plantation or equipment ([CibleTache] + cibleId).
///
/// See `docs/05-modele-de-domaine.md` §6.
abstract class AbstractRappelRepository {
  /// Active reminders (state `actif`) — the ones the task-generation engine
  /// iterates over.
  Future<List<Rappel>> obtenirActifs();

  /// Reminders attached to a given target.
  Future<List<Rappel>> obtenirParCible(CibleTache cible, String cibleId);

  Future<Rappel?> obtenirParId(String id);
  Future<void> sauvegarder(Rappel rappel);

  /// Soft-deletes the reminder.
  Future<void> supprimer(String id);
}
