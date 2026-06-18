/// The mechanism by which two plants *conflict* when grown nearby (ADR-0010,
/// Décision 1). Typing the mechanism lets the app explain *why* a pairing is to
/// be avoided and, for the derivable ones, suggest the conflict on its own.
///
/// See `docs/05` §5.
enum TypeConflitAssociation {
  /// Same botanical family → shared pests and diseases (referential
  /// `Bioagresseur`, ADR-0006). Derivable from `A.famille == B.famille`.
  memeFamilleRavageurs,

  /// Two tall, full-sun plants competing for light side by side.
  competitionLumiere,

  /// Two heavy nitrogen feeders competing for the same nutrient.
  competitionAzote,

  /// Two plants competing for water when grown too close (e.g. thirsty crops
  /// side by side in dry conditions). ADR-0013.
  competitionEau,

  /// Two spreading/bulky plants competing for room (e.g. two cucurbits). ADR-0013.
  competitionEspace,

  /// Plants sharing a common fungal/soil pathogen (host plant), even across
  /// botanical families (e.g. potato + tomato, Verticillium; strawberry +
  /// brassica, soil diseases) — distinct from [memeFamilleRavageurs] (same
  /// family). **Curated only**, not derivable (ADR-0013).
  partageMaladies,

  /// Allelopathy — a plant chemically inhibits another (e.g. fennel, walnut's
  /// juglone). **Curated only**, not derivable.
  allelopathie,
}
