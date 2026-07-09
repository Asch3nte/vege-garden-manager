import '../value_objects/localisation.dart';

/// The location weather features may use, given the user's automatic-weather
/// opt-out (`PreferencesUtilisateur.meteoAutoActive`).
///
/// When weather is on, returns the garden's [position] unchanged. When off,
/// returns [Localisation.nonDefinie] so every weather surface degrades exactly
/// as it does without a position — **no coordinates leave the device** (no
/// Open-Meteo call), while a manual position still drives local season/climate
/// derivation and the watering engine keeps advising from plant needs alone.
Localisation localisationPourMeteo(
  Localisation position, {
  required bool meteoAutoActive,
}) =>
    meteoAutoActive ? position : const Localisation.nonDefinie();
