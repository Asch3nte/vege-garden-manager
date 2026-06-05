/// How soon a plantation needs watering, as decided by the watering engine.
///
/// See `docs/02-fonctionnalites-v1.md` §6.
enum UrgenceArrosage {
  /// Water now: the soil is dry and the plant's demand is high.
  arroserMaintenant,

  /// Water soon (within a few days): demand is moderate, no rain expected yet.
  bientot,

  /// No need to water: recent/forecast rain or strong water retention cover it.
  pasNecessaire,
}
