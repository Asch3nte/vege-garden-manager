import '../entities/preferences_utilisateur.dart';

/// Contract for loading, saving and resetting the user preferences singleton.
abstract class AbstractPreferencesRepository {
  /// Loads the preferences (returns sensible defaults on first run).
  Future<PreferencesUtilisateur> charger();

  /// Persists [preferences].
  Future<void> sauvegarder(PreferencesUtilisateur preferences);

  /// Resets the preferences to their defaults.
  Future<void> reinitialiser();
}
