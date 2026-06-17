/// Direction of a companion association, **seen from the centre plant**
/// (ADR-0012). Lets the view draw oriented arrows and filter by direction.
enum SensAssociation {
  /// The centre helps the other plant (centre → X).
  donne,

  /// The other plant helps the centre (X → centre).
  recoit,

  /// Both ways (↔) — e.g. mutual scent confusion, or a shared-family conflict.
  mutuel,
}

/// Combining directions when aggregating the two resolution directions.
extension SensAssociationX on SensAssociation {
  /// Merges two directions: identical stays as-is; opposite (donne + recoit)
  /// becomes [SensAssociation.mutuel]; anything with [SensAssociation.mutuel]
  /// stays mutuel.
  SensAssociation combiner(SensAssociation autre) =>
      this == autre ? this : SensAssociation.mutuel;
}
