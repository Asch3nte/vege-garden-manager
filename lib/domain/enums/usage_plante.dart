/// Functional roles of a plant (multi-valued, at least one).
///
/// See `docs/05-modele-de-domaine.md` §5 (ADR-0002 D1).
enum UsagePlante {
  alimentaire,
  condimentaire,
  medicinale,
  compagnonnage,
  repulsif,
  mellifere,
  pollinisateur,

  /// Attracts beneficial insects — predators/parasitoids that regulate a
  /// neighbour's pests (ADR-0014, e.g. dill, fennel). Distinct from
  /// [pollinisateur] (pollination).
  attireAuxiliaires,
  engraisVert,
  couvreSol,
  briseVent,
  tuteurVivant,
  ornementale,
  fourrage,
}
