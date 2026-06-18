/// Drought tolerance of a cultivated plant.
///
/// Affects the watering engine's demand index (ADR-0015 Décision 4).
enum ToleranceSecheresse {
  /// Drought-sensitive: stress appears quickly without watering (×1.2 demand).
  faible,

  /// Average tolerance (×1.0 demand).
  moyenne,

  /// Drought-tolerant: can wait longer between waterings (×0.8 demand).
  forte,
}
