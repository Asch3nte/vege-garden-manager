/// V1 thresholds and horizons used by the recommendation/alert engine.
///
/// Centralised here (single source of truth) and **frozen for V1**
/// (`docs/13-roadmap-et-versioning.md` lists them as configurable later). The
/// infrastructure weather client references the same temperature thresholds.
abstract final class SeuilsMeteo {
  /// A day's minimum temperature at or below this (°C) is a frost risk.
  static const double gelC = 0;

  /// A day's maximum temperature at or above this (°C) is a heatwave risk.
  static const double caniculeC = 35;

  /// A day's precipitation at or above this (mm) is a heavy-rain risk.
  static const double fortePluieMmJour = 30;

  /// Default look-ahead, in days, for in-place weather alerts.
  static const int horizonAlertesJours = 3;
}
