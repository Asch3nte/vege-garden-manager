import '../enums/cible_observation.dart';
import '../enums/gravite_observation.dart';
import '../enums/type_observation.dart';

/// A dated journal entry (disease, pest, growth, flowering…) attached to a
/// **polymorphic target**: a potager, a parcelle or a plantation.
///
/// `Observation` is an **entity** (identity by [id]); the [id] is a UUID
/// generated app-side and injected. Photos are deferred to V1.1.
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §3.7 (ADR-0004 D6).
class Observation {
  final String _id;
  final CibleObservation _cible;
  final String _cibleId;
  final DateTime _date;
  final TypeObservation _type;
  GraviteObservation _gravite;
  final String _titre;
  final String? _description;
  bool _resolu;
  DateTime? _dateResolution;
  String? _actionsRealisees;
  String? _notes;

  Observation._(
    this._id,
    this._cible,
    this._cibleId,
    this._date,
    this._type,
    this._gravite,
    this._titre,
    this._description,
    this._resolu,
    this._dateResolution,
    this._actionsRealisees,
    this._notes,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_cibleId.isNotEmpty, 'cibleId must not be empty'),
        assert(_titre.isNotEmpty, 'titre must not be empty'),
        assert(
          _resolu == (_dateResolution != null),
          'resolu is true iff a resolution date is set',
        ),
        assert(
          _dateResolution == null || !_dateResolution.isBefore(_date),
          'the resolution date cannot precede the observation date',
        );

  /// Logs an observation. Unresolved by default, severity defaults to `info`.
  factory Observation({
    required String id,
    required CibleObservation cible,
    required String cibleId,
    required DateTime date,
    required TypeObservation type,
    required String titre,
    GraviteObservation gravite = GraviteObservation.info,
    String? description,
    bool resolu = false,
    DateTime? dateResolution,
    String? actionsRealisees,
    String? notes,
  }) =>
      Observation._(
        id,
        cible,
        cibleId,
        date,
        type,
        gravite,
        titre,
        description,
        resolu,
        dateResolution,
        actionsRealisees,
        notes,
      );

  String get id => _id;
  CibleObservation get cible => _cible;
  String get cibleId => _cibleId;
  DateTime get date => _date;
  TypeObservation get type => _type;
  GraviteObservation get gravite => _gravite;
  String get titre => _titre;
  String? get description => _description;
  bool get resolu => _resolu;
  DateTime? get dateResolution => _dateResolution;
  String? get actionsRealisees => _actionsRealisees;
  String? get notes => _notes;

  /// Re-assesses the severity of the observation.
  void changerGravite(GraviteObservation gravite) => _gravite = gravite;

  /// Sets or clears the free-text notes.
  void modifierNotes(String? notes) => _notes = notes;

  /// Marks the observation as resolved on [date], optionally recording the
  /// [actions] taken. [date] must not precede the observation date.
  void resoudre(DateTime date, {String? actions}) {
    assert(
      !date.isBefore(_date),
      'the resolution date cannot precede the observation date',
    );
    _resolu = true;
    _dateResolution = date;
    _actionsRealisees = actions;
  }

  /// Reopens a resolved observation, clearing its resolution data.
  void rouvrir() {
    _resolu = false;
    _dateResolution = null;
    _actionsRealisees = null;
  }

  @override
  bool operator ==(Object other) => other is Observation && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() =>
      'Observation($_id, ${_type.name} sur ${_cible.name}:$_cibleId)';
}
