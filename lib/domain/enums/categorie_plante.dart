/// Primary (exclusive) filing category of a plant — corresponds to an asset
/// folder. Functional roles are carried separately by `UsagePlante`.
///
/// See `docs/05-modele-de-domaine.md` §5 (ADR-0002 D1).
enum CategoriePlante {
  legume,
  aromatique,
  fruit,
  petitFruit,
  fleur,
  cereale,
  engraisVert,
}
