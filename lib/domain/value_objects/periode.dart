/// Immutable value object representing a recurring range of months in a year.
///
/// Months are integers from 1 (January) to 12 (December). The range is inclusive
/// of both bounds and **may wrap around the end of the year**: a period from 11
/// (November) to 2 (February) covers November, December, January and February.
///
/// Domain names are kept in French (inherited from the specification); the code
/// and its documentation are written in English.
///
/// See `docs/05-modele-de-domaine.md` §4.2.
///
/// Note: `compatibleAvec(ZoneClimatique)` is deliberately not implemented here.
/// A bare month range carries no climate information; the real rule ("is this
/// plant plantable this month in this zone") needs the plant and the hemisphere,
/// so it belongs to the recommendation engine.
class Periode {
  /// First month of the period (1–12).
  final int _moisDebut;

  /// Last month of the period (1–12), inclusive.
  final int _moisFin;

  /// Creates a period spanning from [moisDebut] to [moisFin], both inclusive and
  /// in the range 1–12. When [moisDebut] is greater than [moisFin] the period
  /// wraps across the end of the year (e.g. `Periode(11, 2)` = Nov→Feb).
  const Periode(this._moisDebut, this._moisFin)
      : assert(
          _moisDebut >= 1 && _moisDebut <= 12,
          'moisDebut must be in 1..12',
        ),
        assert(_moisFin >= 1 && _moisFin <= 12, 'moisFin must be in 1..12');

  /// First month of the period (1–12).
  int get moisDebut => _moisDebut;

  /// Last month of the period (1–12), inclusive.
  int get moisFin => _moisFin;

  /// Whether the period wraps across the end of the year (e.g. Nov → Feb).
  bool get chevaucheAnnee => _moisDebut > _moisFin;

  /// Number of months covered by the period, counting both bounds.
  int get dureeEnMois => chevaucheAnnee
      ? (12 - _moisDebut + 1) + _moisFin
      : _moisFin - _moisDebut + 1;

  /// Whether [mois] (1–12) falls within the period.
  bool contientMois(int mois) {
    assert(mois >= 1 && mois <= 12, 'mois must be in 1..12');
    return chevaucheAnnee
        ? mois >= _moisDebut || mois <= _moisFin
        : mois >= _moisDebut && mois <= _moisFin;
  }

  /// Whether [date] falls within the period, based on its month.
  bool contient(DateTime date) => contientMois(date.month);

  @override
  bool operator ==(Object other) =>
      other is Periode &&
      other._moisDebut == _moisDebut &&
      other._moisFin == _moisFin;

  @override
  int get hashCode => Object.hash(_moisDebut, _moisFin);

  @override
  String toString() => 'Periode($_moisDebut→$_moisFin)';
}
