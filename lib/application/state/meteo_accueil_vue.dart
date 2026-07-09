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
/// When [disponible] is false there is no weather to show: either no usable
/// position exists ([desactivee] false → the card prompts to set one), or the
/// user turned automatic weather off ([desactivee] true → a neutral "weather
/// off" state, no misleading position prompt). Otherwise it carries today's
/// temperature range, a [verdict] and a frost flag.
class MeteoAccueilVue {
  final bool _disponible;
  final bool _desactivee;
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
    this._desactivee,
  );

  /// Weather is available for the garden's position.
  factory MeteoAccueilVue.disponible({
    required double tempMin,
    required double tempMax,
    required VerdictMeteo verdict,
    bool risqueGel = false,
  }) =>
      MeteoAccueilVue._(true, tempMin, tempMax, verdict, risqueGel, false);

  /// No usable position → no weather (the card prompts to set a location).
  factory MeteoAccueilVue.indisponible() =>
      const MeteoAccueilVue._(false, 0, 0, VerdictMeteo.clement, false, false);

  /// A position exists but automatic weather fetching is off (privacy opt-out):
  /// the card shows a neutral "weather off" state, never the position prompt.
  factory MeteoAccueilVue.desactivee() =>
      const MeteoAccueilVue._(false, 0, 0, VerdictMeteo.clement, false, true);

  /// Whether weather could be resolved (a position exists and weather is on).
  bool get disponible => _disponible;

  /// Whether automatic weather fetching is off (position may still be set).
  bool get desactivee => _desactivee;

  /// Today's minimum temperature (°C).
  double get tempMin => _tempMin;

  /// Today's maximum temperature (°C).
  double get tempMax => _tempMax;

  /// The watering verdict.
  VerdictMeteo get verdict => _verdict;

  /// Whether a frost risk is flagged for today.
  bool get risqueGel => _risqueGel;
}
