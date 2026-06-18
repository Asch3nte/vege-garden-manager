/// Sky-condition categories derived from a WMO weather interpretation code.
///
/// Used by [GenerateurResumeMeteo] to produce French summary text and by the
/// weather-detail UI to select the appropriate icon. See ADR-0016 Lot 3.
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
  orage,
}
