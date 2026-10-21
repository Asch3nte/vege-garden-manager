/// Kind of weather alert raised against the cultures in place.
enum TypeAlerteMeteo {
  /// Frost risk: a forecast day's minimum temperature is at or below the
  /// threshold.
  gel,

  /// Heatwave risk: a forecast day's maximum temperature is at or above the
  /// threshold.
  canicule,

  /// Heavy-rain risk: a forecast day's precipitation is at or above the
  /// threshold.
  fortePluie,
}
