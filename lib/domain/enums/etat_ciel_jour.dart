/// Sky-condition categories derived from a WMO weather interpretation code.
///
/// Used by the weather-detail UI for its summary text and icon.
enum EtatCielJour {
  /// WMO 0–1: clear or mainly clear sky.
  ensoleille,

  /// WMO 2: partly cloudy.
  nuageux,

  /// WMO 3: overcast.
  couvert,

  /// WMO 45, 48: fog or depositing rime fog.
  brouillard,

  /// WMO 51–67, 80–82: drizzle, rain, or rain showers.
  pluie,

  /// WMO 71–77, 85–86: snow or snow showers.
  neige,

  /// WMO 95–99: thunderstorm (with or without hail).
  orage;

  /// Category of a WMO weather interpretation [code] (0–99); unknown or
  /// out-of-range codes default to [couvert].
  static EtatCielJour depuisWmo(int code) {
    if (code <= 1) return ensoleille;
    if (code == 2) return nuageux;
    if (code == 3) return couvert;
    if (code == 45 || code == 48) return brouillard;
    if (code >= 51 && code <= 67) return pluie;
    if (code >= 71 && code <= 77) return neige;
    if (code >= 80 && code <= 82) return pluie;
    if (code == 85 || code == 86) return neige;
    if (code >= 95 && code <= 99) return orage;
    return couvert;
  }
}
