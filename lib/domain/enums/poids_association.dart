/// How much a user values a family of association effects (ADR-0011).
///
/// A weight scales the score of every suggestion in its effect family.
/// [ignore] (×0) makes the family disappear entirely — e.g. a gardener who finds
/// repellent companions don't work on their plot can turn that family off.
enum PoidsAssociation {
  /// Not valued at all (×0) — suggestions of this family are dropped.
  ignore,

  /// Valued less than usual (×0.5).
  faible,

  /// The default weight (×1.0).
  normal,

  /// Valued more than usual (×1.5).
  fort,
}

/// Score multiplier carried by each [PoidsAssociation] level.
extension PoidsAssociationX on PoidsAssociation {
  /// The multiplier applied to a suggestion's score.
  double get multiplicateur => switch (this) {
        PoidsAssociation.ignore => 0.0,
        PoidsAssociation.faible => 0.5,
        PoidsAssociation.normal => 1.0,
        PoidsAssociation.fort => 1.5,
      };
}
