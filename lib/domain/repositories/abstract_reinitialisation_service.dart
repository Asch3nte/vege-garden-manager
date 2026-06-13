/// Contract for a **factory reset** of the local database.
///
/// Implemented over drift in the infrastructure layer. Destructive and
/// irreversible: every row of user data is wiped and the preferences are reset
/// to their defaults, so the app returns to its first-run state (the onboarding
/// flow runs again). The UI must gate this behind an explicit double
/// confirmation. See `docs/11-parametres-et-opt-outs.md` §5 and `docs/15` §6.
abstract class AbstractReinitialisationService {
  /// Wipes all local data and reseeds the default preferences singleton
  /// (`onboardingTermine == false`), leaving the database in its first-run
  /// state.
  Future<void> reinitialiserTout();
}
