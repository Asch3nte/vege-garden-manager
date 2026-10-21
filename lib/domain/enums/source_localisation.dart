/// Origin of a [Localisation]'s coordinates.
///
/// This describes **where the data came from**, not the user's global geolocation
/// preference (that lives in the preferences).
enum SourceLocalisation {
  /// No location set (privacy default / opt-out).
  nonDefinie,

  /// Entered manually by the user (city + coordinates).
  manuelle,

  /// Obtained from the device GPS.
  gps,
}
