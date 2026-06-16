/// Confidence level of a *derived* companion-planting suggestion (ADR-0010,
/// Lot 3). The derivation engine infers associations from plant traits/usages;
/// some inferences are clear-cut, others approximate — this qualifies how sure
/// the suggestion is, so the UI can present it honestly and the recommendation
/// engine can weight or filter it.
enum NiveauConfiance {
  /// Weak signal — a generic or loosely-approximated inference.
  faible,

  /// Reasonable signal — a plausible inference from a couple of traits.
  moyen,

  /// Strong signal — backed by clear, specific data (e.g. nitrogen fixer ×
  /// heavy feeder, repellent × a pest the family is prone to).
  eleve,
}
