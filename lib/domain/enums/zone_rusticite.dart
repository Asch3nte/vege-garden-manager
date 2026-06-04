/// USDA hardiness zone — the cold tolerance dimension of a climate, based on the
/// average annual extreme minimum temperature.
///
/// See `docs/05-modele-de-domaine.md` §4.6 & §5.
enum ZoneRusticite {
  zone1,
  zone2,
  zone3,
  zone4,
  zone5,
  zone6,
  zone7,
  zone8,
  zone9,
  zone10,
  zone11,
  zone12,
  zone13,
}

/// Temperature data attached to a [ZoneRusticite].
extension ZoneRusticiteX on ZoneRusticite {
  /// Zone number, 1–13.
  int get numero => index + 1;

  /// Lower bound (coldest) of the zone's average annual extreme-minimum
  /// temperature, in °C (USDA scale). Used to reason about frost.
  double get temperatureExtremeMinC => switch (this) {
        ZoneRusticite.zone1 => -50,
        ZoneRusticite.zone2 => -45,
        ZoneRusticite.zone3 => -40,
        ZoneRusticite.zone4 => -34,
        ZoneRusticite.zone5 => -29,
        ZoneRusticite.zone6 => -23,
        ZoneRusticite.zone7 => -18,
        ZoneRusticite.zone8 => -12,
        ZoneRusticite.zone9 => -7,
        ZoneRusticite.zone10 => -1,
        ZoneRusticite.zone11 => 4,
        ZoneRusticite.zone12 => 10,
        ZoneRusticite.zone13 => 16,
      };

  /// Whether this hardiness zone normally experiences frost (minimums reach
  /// freezing). True for zones 1–10, false for the frost-free zones 11–13.
  bool get connaitLeGel => temperatureExtremeMinC < 0;
}
