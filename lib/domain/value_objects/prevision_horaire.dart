/// Immutable hourly forecast point (carried by `AbstractMeteoService`), for the
/// weather detail view.
///
/// [probabilitePluie] is a 0..1 fraction. [weathercode] is the WMO weather
/// interpretation code (0–99). Domain names are French; code/docs are English.
/// See `docs/05-modele-de-domaine.md` §7 and ADR-0016 Lot 2.
class PrevisionHoraire {
  final DateTime _heure;
  final double _temperature;
  final double _precipitationsMm;
  final double _probabilitePluie;
  final int _weathercode;
  final double _ventKmh;

  const PrevisionHoraire._(
    this._heure,
    this._temperature,
    this._precipitationsMm,
    this._probabilitePluie,
    this._weathercode,
    this._ventKmh,
  )   : assert(_precipitationsMm >= 0, 'precipitations must be >= 0'),
        assert(
          _probabilitePluie >= 0 && _probabilitePluie <= 1,
          'rain probability must be in 0..1',
        ),
        assert(_ventKmh >= 0, 'wind speed must be >= 0');

  const PrevisionHoraire({
    required DateTime heure,
    required double temperature,
    required double precipitationsMm,
    double probabilitePluie = 0,
    int weathercode = 0,
    double ventKmh = 0,
  }) : this._(
          heure,
          temperature,
          precipitationsMm,
          probabilitePluie,
          weathercode,
          ventKmh,
        );

  /// The local hour this point describes.
  DateTime get heure => _heure;

  /// Air temperature (°C).
  double get temperature => _temperature;

  /// Precipitation over the hour (mm).
  double get precipitationsMm => _precipitationsMm;

  /// Probability of precipitation (0..1).
  double get probabilitePluie => _probabilitePluie;

  /// WMO weather interpretation code (0–99; 0 = clear sky).
  int get weathercode => _weathercode;

  /// Wind speed at 10 m (km/h).
  double get ventKmh => _ventKmh;

  @override
  bool operator ==(Object other) =>
      other is PrevisionHoraire &&
      other._heure == _heure &&
      other._temperature == _temperature &&
      other._precipitationsMm == _precipitationsMm &&
      other._probabilitePluie == _probabilitePluie &&
      other._weathercode == _weathercode &&
      other._ventKmh == _ventKmh;

  @override
  int get hashCode => Object.hash(
        _heure,
        _temperature,
        _precipitationsMm,
        _probabilitePluie,
        _weathercode,
        _ventKmh,
      );
}
