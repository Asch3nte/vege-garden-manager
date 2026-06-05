import '../enums/urgence_arrosage.dart';

/// Immutable watering advice for a plantation: a **result** value object
/// produced by the engine (`BilanArrosage` / `CalculerBesoinArrosage`), not
/// persisted.
///
/// It carries only structured data; the user-facing message
/// (e.g. *« vos tomates auront besoin d'eau dans 2 jours, aucune pluie
/// prévue »*) is built and localised at the presentation layer. The structured
/// flags let the UI explain the advice.
///
/// Domain names are kept in French; the code is documented in English.
class ConseilArrosage {
  final UrgenceArrosage _urgence;
  final int? _joursAvantArrosage;
  final bool _pluieRecente;
  final bool _pluiePrevue;
  final bool _retentionRenforcee;
  final double _indiceBesoin;

  ConseilArrosage._(
    this._urgence,
    this._joursAvantArrosage,
    this._pluieRecente,
    this._pluiePrevue,
    this._retentionRenforcee,
    this._indiceBesoin,
  );

  /// Builds an advice. [indiceBesoin] is the engine's internal demand index in
  /// `0..1` (higher = drier/needier).
  factory ConseilArrosage({
    required UrgenceArrosage urgence,
    int? joursAvantArrosage,
    bool pluieRecente = false,
    bool pluiePrevue = false,
    bool retentionRenforcee = false,
    required double indiceBesoin,
  }) {
    assert(indiceBesoin >= 0 && indiceBesoin <= 1,
        'indiceBesoin must be in 0..1');
    assert(joursAvantArrosage == null || joursAvantArrosage >= 0,
        'joursAvantArrosage must be >= 0');
    return ConseilArrosage._(
      urgence,
      joursAvantArrosage,
      pluieRecente,
      pluiePrevue,
      retentionRenforcee,
      indiceBesoin,
    );
  }

  UrgenceArrosage get urgence => _urgence;

  /// Days until watering is needed (e.g. 0 = now, 2 = in two days), or `null`
  /// when not applicable.
  int? get joursAvantArrosage => _joursAvantArrosage;

  /// Whether recent days brought enough rain to keep the soil moist.
  bool get pluieRecente => _pluieRecente;

  /// Whether significant rain is forecast soon.
  bool get pluiePrevue => _pluiePrevue;

  /// Whether soil/technique/equipment retention noticeably lowers the need.
  bool get retentionRenforcee => _retentionRenforcee;

  /// Internal demand index in `0..1` (higher = needs water more).
  double get indiceBesoin => _indiceBesoin;

  @override
  bool operator ==(Object other) =>
      other is ConseilArrosage &&
      other._urgence == _urgence &&
      other._joursAvantArrosage == _joursAvantArrosage &&
      other._pluieRecente == _pluieRecente &&
      other._pluiePrevue == _pluiePrevue &&
      other._retentionRenforcee == _retentionRenforcee &&
      other._indiceBesoin == _indiceBesoin;

  @override
  int get hashCode => Object.hash(_urgence, _joursAvantArrosage, _pluieRecente,
      _pluiePrevue, _retentionRenforcee, _indiceBesoin);

  @override
  String toString() => 'ConseilArrosage(${_urgence.name}, '
      'dans ${_joursAvantArrosage ?? '-'} j, indice $_indiceBesoin)';
}
