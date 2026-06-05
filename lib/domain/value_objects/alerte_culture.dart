import '../enums/type_alerte_meteo.dart';

/// Immutable weather alert raised against the cultures in place for a given day.
///
/// A **result** value object produced by the engine (`EvaluateurAlertesMeteo` /
/// `DetecterAlertesMeteo`), not persisted. It carries only structured data:
/// the user-facing message is built and localised at the presentation layer
/// (the VO never holds a French string).
///
/// In V1 the alert is **generic** — [plantationsConcernees] lists every culture
/// in place in the concerned potager, with no per-plant sensitivity filtering
/// (no such data exists in the catalogue yet; see `docs/13` §2.1).
///
/// Domain names are kept in French; the code is documented in English.
class AlerteCulture {
  final TypeAlerteMeteo _type;
  final DateTime _date;
  final double _valeurDeclenchante;
  final List<String> _plantationsConcernees;

  AlerteCulture._(
    this._type,
    this._date,
    this._valeurDeclenchante,
    this._plantationsConcernees,
  );

  /// Creates an alert. [valeurDeclenchante] is the figure that crossed the
  /// threshold (min temperature for [TypeAlerteMeteo.gel], max temperature for
  /// [TypeAlerteMeteo.canicule], precipitation in mm for
  /// [TypeAlerteMeteo.fortePluie]).
  factory AlerteCulture({
    required TypeAlerteMeteo type,
    required DateTime date,
    required double valeurDeclenchante,
    required List<String> plantationsConcernees,
  }) =>
      AlerteCulture._(
        type,
        date,
        valeurDeclenchante,
        List<String>.unmodifiable(plantationsConcernees),
      );

  TypeAlerteMeteo get type => _type;

  /// The forecast day the alert applies to.
  DateTime get date => _date;

  /// The figure that crossed the threshold (°C or mm, per [type]).
  double get valeurDeclenchante => _valeurDeclenchante;

  /// Ids of the in-place plantations concerned (unmodifiable).
  List<String> get plantationsConcernees => _plantationsConcernees;

  @override
  bool operator ==(Object other) =>
      other is AlerteCulture &&
      other._type == _type &&
      other._date == _date &&
      other._valeurDeclenchante == _valeurDeclenchante &&
      _memesElements(other._plantationsConcernees, _plantationsConcernees);

  @override
  int get hashCode => Object.hash(
        _type,
        _date,
        _valeurDeclenchante,
        Object.hashAll(_plantationsConcernees),
      );

  static bool _memesElements(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'AlerteCulture(${_type.name}, $_date, $_valeurDeclenchante, '
      '${_plantationsConcernees.length} plantation(s))';
}
