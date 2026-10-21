import '../entities/preferences_utilisateur.dart';
import '../exceptions/preferences_illisibles_exception.dart';

/// Contract for loading, saving and resetting the user preferences singleton.
abstract class AbstractPreferencesRepository {
  /// Loads the preferences (returns sensible defaults on first run).
  Future<PreferencesUtilisateur> charger();

  /// Persists [preferences].
  ///
  /// Throws [PreferencesIllisiblesException] while the stored preferences
  /// cannot be read: they are kept untouched.
  Future<void> sauvegarder(PreferencesUtilisateur preferences);

  /// Resets the preferences to their defaults (same restriction as
  /// [sauvegarder]).
  Future<void> reinitialiser();

  /// Whether the stored preferences cannot be read; [charger] then returns
  /// [PreferencesUtilisateur.prudentes].
  Future<bool> sontIllisibles();
}
