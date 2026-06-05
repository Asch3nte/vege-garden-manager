/// Immutable estimated harvest window for a plantation: the range
/// `[dateMin, dateMax]` derived from the planting date plus the plant's
/// minimum/maximum days-to-harvest.
///
/// It is a **result** value object produced by the engine
/// (`CalculateurDatesCulture`), not persisted. Domain names are kept in French;
/// the code is documented in English. See `docs/05-modele-de-domaine.md` §4.
class EstimationRecolte {
  final DateTime _dateMin;
  final DateTime _dateMax;

  const EstimationRecolte._(this._dateMin, this._dateMax);

  /// Builds an estimate; [dateMin] must not be after [dateMax].
  factory EstimationRecolte({
    required DateTime dateMin,
    required DateTime dateMax,
  }) {
    assert(!dateMin.isAfter(dateMax), 'dateMin must not be after dateMax');
    return EstimationRecolte._(dateMin, dateMax);
  }

  /// Earliest expected harvest date.
  DateTime get dateMin => _dateMin;

  /// Latest expected harvest date.
  DateTime get dateMax => _dateMax;

  /// Whether [date] falls within the estimated window (inclusive).
  bool contient(DateTime date) =>
      !date.isBefore(_dateMin) && !date.isAfter(_dateMax);

  @override
  bool operator ==(Object other) =>
      other is EstimationRecolte &&
      other._dateMin == _dateMin &&
      other._dateMax == _dateMax;

  @override
  int get hashCode => Object.hash(_dateMin, _dateMax);

  @override
  String toString() => 'EstimationRecolte($_dateMin → $_dateMax)';
}
