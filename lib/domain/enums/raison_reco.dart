/// Structured reason a plant is recommended (the "Pourquoi" of a recommendation).
///
/// The user-facing, localised explanation is built from these at the
/// presentation layer. See `docs/02-fonctionnalites-v1.md` §2.
enum RaisonReco {
  /// The plant can be put in the ground this month in the user's climate.
  plantableMaintenant,

  /// The parcelle's sun exposure matches the plant's need.
  expositionAdaptee,

  /// The parcelle's soil qualities match the plant's needs.
  solAdapte,

  /// A beneficial companion plant is already growing in the parcelle.
  bonneAssociation,

  /// Crop rotation is respected (no recent same-family culture in this soil).
  rotationFavorable,

  /// The plant's difficulty level matches the user's experience level.
  niveauAdapte,

  /// The plant benefits from (or requires) vertical support available in the
  /// parcelle (trellis, stake…).
  cultureVerticaleCompatible,
}
