/// Growth stage at which a plant is most vulnerable to water stress.
///
/// These are well-documented agronomic facts (not per-plant invented figures):
/// e.g. most fruiting vegetables are critical at fruit set, leafy crops during
/// heading, root crops during swelling. A fiche lists the stages where letting
/// the soil dry out is most damaging, so the detailed watering section can warn
/// the expert gardener. Purely informational — the watering engine
/// (`BilanArrosage`, ADR-0015) does not consume it.
///
/// Domain names are kept in French; the code is documented in English.
enum PhaseSensibleEau {
  /// Germination / seedling emergence — the seedbed must stay evenly moist.
  germination,

  /// Vegetative leaf growth.
  feuillaison,

  /// Flowering — water stress causes flower/bud drop.
  floraison,

  /// Fruit set and development.
  fructification,

  /// Swelling of the harvested organ (root, tuber, bulb, head).
  grossissement,
}
