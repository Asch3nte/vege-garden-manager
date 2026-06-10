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
/// (so no weather): the card invites the user to set one. Otherwise it carries
/// today's temperature range, a [verdict] and a frost flag.
class MeteoAccueilVue {
  final bool _disponible;
  final double _tempMin;
  final double _tempMax;
  final VerdictMeteo _verdict;
  final bool _risqueGel;

  const MeteoAccueilVue._(
    this._disponible,
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
      MeteoAccueilVue._(true, tempMin, tempMax, verdict, risqueGel);

  /// No usable position → no weather (the card prompts to set a location).
  factory MeteoAccueilVue.indisponible() =>
      const MeteoAccueilVue._(false, 0, 0, VerdictMeteo.clement, false);

  /// Whether weather could be resolved (a position exists).
  bool get disponible => _disponible;

  /// Today's minimum temperature (°C).
  double get tempMin => _tempMin;

  /// Today's maximum temperature (°C).
  double get tempMax => _tempMax;

  /// The watering verdict.
  VerdictMeteo get verdict => _verdict;

  /// Whether a frost risk is flagged for today.
  bool get risqueGel => _risqueGel;
}
