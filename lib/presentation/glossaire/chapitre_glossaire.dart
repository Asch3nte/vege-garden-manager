/// The chapters of the « Aide & lexique » glossary — the "book" structure the
/// panel presents (ADR-0017, D1).
///
/// Every [TermeGlossaire] belongs to exactly one chapter. Chapters drive the
/// **organisation** (panel tabs/sections); the term's `TypeTermeGlossaire`
/// drives its **colour**. Labels and icons are resolved on the Presentation
/// side (`libelles_glossaire.dart`), keeping this enum pure and testable.
enum ChapitreGlossaire {
  /// Plant categories, vegetable sub-types, usages, growth stages, planting
  /// methods, plantation statuses.
  culturesEtPlantes,

  /// One page per botanical family (derived from the YAML reference) plus the
  /// transverse notions (botanical family, crop rotation).
  famillesBotaniques,

  /// One page per disease/pest (derived from the YAML reference) plus
  /// prevention notions.
  santeDuJardin,

  /// Soil textures, pH, quality, soil techniques, rooting depths.
  solEtTerre,

  /// Water needs, watering urgency, evapotranspiration, drought tolerance.
  eauEtArrosage,

  /// One page per equipment type (oya, drip irrigation, stakes…).
  outilsEtEquipements,

  /// Climates, hardiness zones, hemispheres, frost/heatwave, weather alerts.
  climatEtSaisons,

  /// Association mechanisms, effect families, directions, confidence.
  associationsEtCompagnonnage,

  /// Task types, priorities, harvests, observations, zones, experience tiers.
  gestesEtOrganisation,
}
