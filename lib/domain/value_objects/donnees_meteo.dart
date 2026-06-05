/// Immutable observed weather data for a given day (DTO carried by
/// `AbstractMeteoService`). `risqueGel`/`risqueCanicule` are pre-computed flags.
///
/// See `docs/05-modele-de-domaine.md` §7.
class DonneesMeteo {
  final DateTime _date;
  final double _tempMin;
  final double _tempMax;
  final double _tempMoyenne;
  final double _precipitationsMm;
  final double _ventVitesseMax;
  final bool _risqueGel;
  final bool _risqueCanicule;

  const DonneesMeteo._(
    this._date,
    this._tempMin,
    this._tempMax,
    this._tempMoyenne,
    this._precipitationsMm,
    this._ventVitesseMax,
    this._risqueGel,
    this._risqueCanicule,
  )   : assert(_tempMin <= _tempMax, 'tempMin must be <= tempMax'),
        assert(_precipitationsMm >= 0, 'precipitations must be >= 0'),
        assert(_ventVitesseMax >= 0, 'wind speed must be >= 0');

  const DonneesMeteo({
    required DateTime date,
    required double tempMin,
    required double tempMax,
    required double tempMoyenne,
    required double precipitationsMm,
    required double ventVitesseMax,
    bool risqueGel = false,
    bool risqueCanicule = false,
  }) : this._(date, tempMin, tempMax, tempMoyenne, precipitationsMm,
            ventVitesseMax, risqueGel, risqueCanicule);

  DateTime get date => _date;
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  double get tempMoyenne => _tempMoyenne;
  double get precipitationsMm => _precipitationsMm;
  double get ventVitesseMax => _ventVitesseMax;
  bool get risqueGel => _risqueGel;
  bool get risqueCanicule => _risqueCanicule;

  @override
  bool operator ==(Object other) =>
      other is DonneesMeteo &&
      other._date == _date &&
      other._tempMin == _tempMin &&
      other._tempMax == _tempMax &&
      other._tempMoyenne == _tempMoyenne &&
      other._precipitationsMm == _precipitationsMm &&
      other._ventVitesseMax == _ventVitesseMax &&
      other._risqueGel == _risqueGel &&
      other._risqueCanicule == _risqueCanicule;

  @override
  int get hashCode => Object.hash(_date, _tempMin, _tempMax, _tempMoyenne,
      _precipitationsMm, _ventVitesseMax, _risqueGel, _risqueCanicule);
}
