import '../enums/type_releve_meteo.dart';

/// Immutable weather forecast for a given day (DTO carried by
/// `AbstractMeteoService`).
///
/// [weathercode] is the WMO weather interpretation code (0–99; 0 = clear sky).
/// When rebuilt from the local cache the code defaults to 0 (the DB column is
/// not stored — ADR-0016 Lot 2 decision: no migration, offline fallback drops
/// the visual code gracefully).
///
/// See `docs/05-modele-de-domaine.md` §7 and ADR-0016.
class PrevisionMeteo {
  final DateTime _date;
  final double _tempMin;
  final double _tempMax;
  final double _precipitationsMm;
  final double _probabilitePluie;
  final TypeReleveMeteo _type;
  final double? _evapotranspirationMm;
  final int _weathercode;

  const PrevisionMeteo._(
    this._date,
    this._tempMin,
    this._tempMax,
    this._precipitationsMm,
    this._probabilitePluie,
    this._type,
    this._evapotranspirationMm,
    this._weathercode,
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
    double? evapotranspirationMm,
    int weathercode = 0,
  }) : this._(
          date,
          tempMin,
          tempMax,
          precipitationsMm,
          probabilitePluie,
          type,
          evapotranspirationMm,
          weathercode,
        );

  DateTime get date => _date;
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  double get precipitationsMm => _precipitationsMm;

  /// Probability of rain, between 0 and 1.
  double get probabilitePluie => _probabilitePluie;
  TypeReleveMeteo get type => _type;

  /// Reference evapotranspiration ET₀ FAO-56 (mm/day), or `null` when not
  /// provided by the weather source (ADR-0015 Lot 5).
  double? get evapotranspirationMm => _evapotranspirationMm;

  /// WMO weather interpretation code (0–99; 0 = clear sky).
  /// Defaults to 0 when rebuilt from the local cache.
  int get weathercode => _weathercode;

  @override
  bool operator ==(Object other) =>
      other is PrevisionMeteo &&
      other._date == _date &&
      other._tempMin == _tempMin &&
      other._tempMax == _tempMax &&
      other._precipitationsMm == _precipitationsMm &&
      other._probabilitePluie == _probabilitePluie &&
      other._type == _type &&
      other._evapotranspirationMm == _evapotranspirationMm &&
      other._weathercode == _weathercode;

  @override
  int get hashCode => Object.hash(
        _date,
        _tempMin,
        _tempMax,
        _precipitationsMm,
        _probabilitePluie,
        _type,
        _evapotranspirationMm,
        _weathercode,
      );
}
