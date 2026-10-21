import 'package:riverpod/riverpod.dart';

import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/enums/famille_effet_association.dart';
import '../../domain/enums/famille_effet_conflit.dart';
import '../../domain/enums/langue.dart';
import '../../domain/enums/mode_geolocalisation.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/poids_association.dart';
import '../../domain/enums/sens_swipe.dart';
import '../../domain/enums/systeme_unites.dart';
import '../../domain/enums/theme_app.dart';
import '../../domain/value_objects/profil_ponderation_associations.dart';
import '../providers/repository_providers.dart';

/// Exposes the user [PreferencesUtilisateur] and the actions that mutate it.
///
/// Every setter applies the change with `copierAvec`, **persists immediately**
/// (auto-save) and reflects the new value in [state]. The single
/// private [_modifier] helper keeps each setter to one line and guarantees the
/// save-then-publish order. All preferences are local-only — no network, no
/// account (privacy by design).
class PreferencesNotifier extends AsyncNotifier<PreferencesUtilisateur> {
  @override
  Future<PreferencesUtilisateur> build() {
    return ref.watch(preferencesRepositoryProvider).charger();
  }

  /// Applies [transformer] to the current preferences, persists, and publishes.
  Future<void> _modifier(
    PreferencesUtilisateur Function(PreferencesUtilisateur p) transformer,
  ) async {
    final courant = state.value;
    if (courant == null) return;
    final misAJour = transformer(courant);
    await ref.read(preferencesRepositoryProvider).sauvegarder(misAJour);
    state = AsyncData(misAJour);
  }

  /// Sets the interface language.
  Future<void> definirLangue(Langue langue) =>
      _modifier((p) => p.copierAvec(langue: langue));

  /// Sets the theme (auto / light / dark).
  Future<void> definirTheme(ThemeApp theme) =>
      _modifier((p) => p.copierAvec(theme: theme));

  /// Sets the unit system.
  Future<void> definirUnites(SystemeUnites unites) =>
      _modifier((p) => p.copierAvec(systemeUnites: unites));

  /// Sets the list-swipe direction.
  Future<void> definirSensSwipe(SensSwipe sens) =>
      _modifier((p) => p.copierAvec(sensSwipe: sens));

  /// Sets the experience level (drives advice verbosity and unlocks).
  Future<void> definirNiveau(NiveauExperience niveau) =>
      _modifier((p) => p.copierAvec(niveauExperience: niveau));

  /// Sets the geolocation mode (off / manual / GPS).
  Future<void> definirGeolocalisation(ModeGeolocalisation mode) =>
      _modifier((p) => p.copierAvec(modeGeolocalisation: mode));

  /// Master notifications switch.
  Future<void> definirNotificationsGlobales(bool actives) =>
      _modifier((p) => p.copierAvec(notificationsGlobalesActives: actives));

  /// Local Wi-Fi sync opt-in.
  Future<void> definirSyncLocale(bool active) =>
      _modifier((p) => p.copierAvec(syncLocaleActive: active));

  /// Lunar-calendar opt-in.
  Future<void> definirCalendrierLunaire(bool actif) =>
      _modifier((p) => p.copierAvec(calendrierLunaireOptIn: actif));

  /// Marks the first-launch onboarding as completed (lifts the router gate).
  Future<void> terminerOnboarding() =>
      _modifier((p) => p.copierAvec(onboardingTermine: true));

  /// Toggles automatic weather fetching (opt-out). When off, no Open-Meteo
  /// call is made automatically (home card, watering advice, alerts).
  Future<void> definirMeteoAuto(bool actif) =>
      _modifier((p) => p.copierAvec(meteoAutoActive: actif));

  /// Sets the do-not-disturb window (`HH:MM` bounds); notifications whose time
  /// falls inside are suppressed by the Application layer.
  Future<void> definirNePasDeranger(String debut, String fin) =>
      _modifier((p) => p.avecNePasDeranger(debut, fin));

  /// Clears the do-not-disturb window.
  Future<void> desactiverNePasDeranger() =>
      _modifier((p) => p.sansNePasDeranger());

  /// Toggles one notification category on/off.
  Future<void> definirNotificationCategorie(String cle, bool actif) {
    return _modifier((p) {
      final map = Map<String, bool>.from(p.notificationsParCategorie)
        ..[cle] = actif;
      return p.copierAvec(notificationsParCategorie: map);
    });
  }

  /// Sets the weight of one association effect family (expert).
  Future<void> definirPoidsAssociation(
    FamilleEffetAssociation famille,
    PoidsAssociation poids,
  ) =>
      _modifier((p) => p.copierAvec(
            ponderationAssociations:
                p.ponderationAssociations.avec(famille, poids),
          ));

  /// Sets the weight of one **conflict** effect family (expert).
  Future<void> definirPoidsConflit(
    FamilleEffetConflit famille,
    PoidsAssociation poids,
  ) =>
      _modifier((p) => p.copierAvec(
            ponderationAssociations:
                p.ponderationAssociations.avecConflit(famille, poids),
          ));

  /// Resets the association weighting profile to the neutral default.
  Future<void> reinitialiserPonderationAssociations() => _modifier(
      (p) => p.copierAvec(
          ponderationAssociations: ProfilPonderationAssociations.defaut()));
}

/// The user-preferences provider.
final preferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, PreferencesUtilisateur>(
  PreferencesNotifier.new,
);

/// Whether the stored preferences cannot be read (prudent defaults apply and
/// changes are refused until they are replaced by an import or a reset).
final preferencesIllisiblesProvider = FutureProvider<bool>((ref) async {
  await ref.watch(preferencesProvider.future);
  return ref.watch(preferencesRepositoryProvider).sontIllisibles();
});
