/// A garden-level watering verdict derived from the weather, shown on the home
/// weather card.
enum VerdictMeteo {
  /// Rain is expected soon — watering can wait.
  pluieAVenir,

  /// Recent rain — the soil is likely still moist.
  solHumide,

  /// Hot and dry — watering is advisable.
  arroserConseille,

  /// Mild conditions, nothing notable.
  clement,
}

/// Immutable view-model for the home **weather card**.
///
/// When [disponible] is false there is no usable position on the active garden
/// (so no weather): the card invites the user to set one. When [meteoDesactivee]
/// is true the auto weather-fetch opt-out is off (docs/11) — no fetch happened
/// and the card is muted. Otherwise it carries today's temperature range, a
/// [verdict] and a frost flag.
class MeteoAccueilVue {
  final bool _disponible;
  final bool _meteoDesactivee;
  final double _tempMin;
  final double _tempMax;
  final VerdictMeteo _verdict;
  final bool _risqueGel;

  const MeteoAccueilVue._(
    this._disponible,
    this._meteoDesactivee,
    this._tempMin,
    this._tempMax,
    this._verdict,
    this._risqueGel,
  );

  /// Weather is available for the garden's position.
  factory MeteoAccueilVue.disponible({
    required double tempMin,
    required double tempMax,
    required VerdictMeteo verdict,
    bool risqueGel = false,
  }) =>
      MeteoAccueilVue._(true, false, tempMin, tempMax, verdict, risqueGel);

  /// No usable position → no weather (the card prompts to set a location).
  factory MeteoAccueilVue.indisponible() =>
      const MeteoAccueilVue._(false, false, 0, 0, VerdictMeteo.clement, false);

  /// Auto weather-fetch is off (opt-out): no fetch was attempted.
  factory MeteoAccueilVue.desactivee() =>
      const MeteoAccueilVue._(false, true, 0, 0, VerdictMeteo.clement, false);

  /// Whether weather could be resolved (a position exists).
  bool get disponible => _disponible;

  /// Whether the auto weather-fetch opt-out is off (docs/11).
  bool get meteoDesactivee => _meteoDesactivee;

  /// Today's minimum temperature (°C).
  double get tempMin => _tempMin;

  /// Today's maximum temperature (°C).
  double get tempMax => _tempMax;

  /// The watering verdict.
  VerdictMeteo get verdict => _verdict;

  /// Whether a frost risk is flagged for today.
  bool get risqueGel => _risqueGel;
}
