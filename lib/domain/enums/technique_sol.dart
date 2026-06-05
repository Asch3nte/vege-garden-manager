/// Soil management techniques applied to a parcelle. Multi-valued and orthogonal
/// to the parcelle structure (`TypeParcelle`): a raised bed can combine several.
///
/// See `docs/05-modele-de-domaine.md` §5.
enum TechniqueSol {
  // Soil structure
  butteLasagne,
  hugelkultur,
  butteRonde,
  buttePermanente,
  // Cover / mulch
  paillage,
  brf,
  mulchVivant,
  engraisVertCouvert,
  paillageMineral,
  carton,
  // No-dig / minimal
  noDig,
  grelinette,
  mulchDeFoin,
  // Amendment / fertility
  compostageSurface,
  compostEnTrou,
  mycorhization,
  bokashi,
  // Water / landscape
  swales,
  keylineDesign,
}
