/// Functional crop group usable as a rotation precedent when a plant references
/// a *role* rather than a single botanical family.
///
/// These are the only two non-family tokens the sheet corpus uses under
/// `rotation.precedents_favorables` / `precedents_defavorables`:
/// nitrogen-fixing legumes and green manures. Both cut across botanical
/// families (a "legume" precedent is satisfied by any nitrogen fixer, a
/// "green manure" precedent by any plant filed under
/// [CategoriePlante.engraisVert]), which is why they cannot be reduced to a
/// family slug — see [PrecedentCultural].
///
/// UI labels are resolved by the presentation layer (i18n); the domain keeps
/// these as opaque roles.
enum GroupeCultural {
  /// Nitrogen-fixing legumes (Fabaceae and functional equivalents). A favorable
  /// precedent for nitrogen-hungry crops.
  legumineuses,

  /// Green manures (cover crops grown to be returned to the soil).
  engraisVerts,
}
