/// Coarse growth stage of an active plantation, from planting to harvest.
///
/// Plant-agnostic on purpose: the catalogue carries only a total days-to-harvest
/// window (no per-species stage curve), so the stage is **derived** by the engine
/// as an assumed proportion of that duration — never a measured value. Enough to
/// give the gardener a sense of progress. A V2 may refine it per species/variety
/// once the fiches carry finer data. See `docs/15-elements-differes.md` §3.
///
/// Domain names are kept in French; the code is documented in English.
enum StadeCroissance {
  /// Just sown, not yet (or barely) emerged. Only reached for sowing methods;
  /// already-established plants (transplant, bought plant…) start at [croissance].
  levee,

  /// Vegetative growth — the bulk of the cycle.
  croissance,

  /// Approaching the estimated harvest window.
  maturation,

  /// Within (or past) the estimated harvest window.
  recolte,
}
