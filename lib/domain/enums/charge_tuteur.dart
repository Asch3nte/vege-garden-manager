/// How heavy a climbing plant is for the support it grows on (ADR-0010, Lot 2).
///
/// Lets the `tuteurStructurel` association rule pick a support strong enough for
/// the climber (e.g. a pole bean is light, a running squash is heavy). When a
/// sheet omits it, the derivation engine approximates from category/height.
enum ChargeTuteur {
  /// Light load — most herbaceous climbers (e.g. pole bean, pea).
  legere,

  /// Moderate load (e.g. cucumber, small melon).
  moyenne,

  /// Heavy load — vigorous, running plants (e.g. squash, gourd).
  lourde,
}
