/// Immutable hourly forecast point (carried by `AbstractMeteoService`), for the
/// weather detail view.
///
/// [probabilitePluie] is a 0..1 fraction. Domain names are French; code/docs are
/// English. See `docs/05-modele-de-domaine.md` §7.
class PrevisionHoraire {
  final DateTime _heure;
  final double _temperature;
  final double _precipitationsMm;
  final double _probabilitePluie;

  const PrevisionHoraire._(
    this._heure,
    this._temperature,
    this._precipitationsMm,
    this._probabilitePluie,
  )   : assert(_precipitationsMm >= 0, 'precipitations must be >= 0'),
        assert(
          _probabilitePluie >= 0 && _probabilitePluie <= 1,
          'rain probability must be in 0..1',
        );

  const PrevisionHoraire({
    required DateTime heure,
    required double temperature,
    required double precipitationsMm,
    double probabilitePluie = 0,
  }) : this._(heure, temperature, precipitationsMm, probabilitePluie);

  /// The local hour this point describes.
  DateTime get heure => _heure;

  /// Air temperature (°C).
  double get temperature => _temperature;

  /// Precipitation over the hour (mm).
  double get precipitationsMm => _precipitationsMm;

  /// Probability of precipitation (0..1).
  double get probabilitePluie => _probabilitePluie;

  @override
  bool operator ==(Object other) =>
      other is PrevisionHoraire &&
      other._heure == _heure &&
      other._temperature == _temperature &&
      other._precipitationsMm == _precipitationsMm &&
      other._probabilitePluie == _probabilitePluie;

  @override
  int get hashCode =>
      Object.hash(_heure, _temperature, _precipitationsMm, _probabilitePluie);
}
