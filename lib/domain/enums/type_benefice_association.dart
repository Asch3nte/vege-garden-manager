/// The mechanism by which a plant *benefits* a companion grown nearby
/// (ADR-0010, Décision 1). Typing the mechanism — rather than relying on free
/// text — lets the app *reason* about associations (derivation, placement) and
/// display a localised, meaningful reason instead of opaque prose.
///
/// Most mechanisms are derivable from existing traits/usages/bioaggressors; the
/// curated layer may also state one explicitly on a pair. See `docs/05` §5.
enum TypeBeneficeAssociation {
  /// One plant physically supports a climbing neighbour (e.g. maize + pole
  /// bean). Derivable from a sturdy/tall support × a vertical-growing climber.
  tuteurStructurel,

  /// Layering the canopy / shading plants that tolerate shade (e.g. maize over
  /// lettuce; tomato + basil).
  etagementLumiere,

  /// A repellent plant keeps a targeted pest away from a susceptible neighbour
  /// (e.g. tomato + marigold).
  repulsionRavageur,

  /// A blend of smells that confuses pests, often mutual (e.g. carrot + onion).
  brouillageOlfactif,

  /// Attracting pollinators to the benefit of an entomophilous plant (e.g.
  /// borage + courgette).
  attractionPollinisateurs,

  /// Diverting a pest onto a decoy/trap plant (e.g. nasturtium + broad bean for
  /// aphids).
  plantePiege,

  /// A legume enriches the soil in nitrogen for a hungry neighbour (e.g. bean +
  /// maize).
  fixationAzote,

  /// Covering the soil (against weeds, to keep moisture) — e.g. squash in the
  /// milpa.
  couvreSol,

  /// Sheltering neighbours from the wind (e.g. a hedge protecting sensitive
  /// crops).
  briseVent,

  /// A short cycle and a long cycle sharing the same spot in time (e.g. radish +
  /// carrot; garlic + corn salad).
  successionTemporelle,
}
