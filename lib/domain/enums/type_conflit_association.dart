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

  /// Allelopathy — a plant chemically inhibits another (e.g. fennel, walnut's
  /// juglone). **Curated only**, not derivable.
  allelopathie,
}
