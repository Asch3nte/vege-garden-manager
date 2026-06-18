/// Aggregated station information displayed in the weather-detail header.
///
/// [nomVille] comes from Nominatim reverse-geocoding (null if unavailable).
/// [elevation] (metres) comes from the Open-Meteo forecast response metadata
/// (null if unavailable). See ADR-0016 Lot 2.
class InfosStation {
  final String? nomVille;
  final double? elevation;

  const InfosStation({this.nomVille, this.elevation});

  /// True when at least one piece of station information is available.
  bool get disponible => nomVille != null || elevation != null;
}
