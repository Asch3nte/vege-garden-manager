import '../enums/type_releve_meteo.dart';

/// Immutable weather forecast for a given day (DTO carried by
/// `AbstractMeteoService`).
///
/// See `docs/05-modele-de-domaine.md` §7.
class PrevisionMeteo {
  final DateTime _date;
  final double _tempMin;
  final double _tempMax;
  final double _precipitationsMm;
  final double _probabilitePluie;
  final TypeReleveMeteo _type;

  const PrevisionMeteo._(
    this._date,
    this._tempMin,
    this._tempMax,
    this._precipitationsMm,
    this._probabilitePluie,
    this._type,
  )   : assert(_tempMin <= _tempMax, 'tempMin must be <= tempMax'),
        assert(_precipitationsMm >= 0, 'precipitations must be >= 0'),
        assert(
          _probabilitePluie >= 0 && _probabilitePluie <= 1,
          'rain probability must be in 0..1',
        );

  const PrevisionMeteo({
    required DateTime date,
    required double tempMin,
    required double tempMax,
    required double precipitationsMm,
    double probabilitePluie = 0,
    TypeReleveMeteo type = TypeReleveMeteo.prevu,
  }) : this._(
            date, tempMin, tempMax, precipitationsMm, probabilitePluie, type);

  DateTime get date => _date;
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  double get precipitationsMm => _precipitationsMm;

  /// Probability of rain, between 0 and 1.
  double get probabilitePluie => _probabilitePluie;
  TypeReleveMeteo get type => _type;

  @override
  bool operator ==(Object other) =>
      other is PrevisionMeteo &&
      other._date == _date &&
      other._tempMin == _tempMin &&
      other._tempMax == _tempMax &&
      other._precipitationsMm == _precipitationsMm &&
      other._probabilitePluie == _probabilitePluie &&
      other._type == _type;

  @override
  int get hashCode => Object.hash(_date, _tempMin, _tempMax, _precipitationsMm,
      _probabilitePluie, _type);
}
