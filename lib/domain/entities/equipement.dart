import '../enums/etat_equipement.dart';
import '../enums/type_equipement.dart';
import '../value_objects/effet_equipement.dart';

/// An installation on a parcelle (oya, voile, tuteur…) or shared across the
/// potager.
///
/// Always attached to a [potagerId]; a null [parcelleId] means the equipment is
/// transverse (e.g. a composter, a rain barrel). Equipment is never deleted —
/// retiring it records a [dateRetrait] but keeps it for history. Its agronomic
/// [effet] is derived from its [type] (not stored).
///
/// `Equipement` is an **entity** (identity by [id]); the [id] is a UUID generated
/// app-side and injected. Domain names are kept in French; the code is
/// documented in English. See `docs/05-modele-de-domaine.md` §3.7.
class Equipement {
  final String _id;
  final String _nom;
  final String _potagerId;
  final String? _parcelleId;
  final TypeEquipement _type;
  EtatEquipement _etat;
  final String? _marqueModele;
  final DateTime _dateInstallation;
  final DateTime? _dateRemplacementPrevue;
  DateTime? _dateRetrait;
  String? _notes;

  Equipement._(
    this._id,
    this._nom,
    this._potagerId,
    this._parcelleId,
    this._type,
    this._etat,
    this._marqueModele,
    this._dateInstallation,
    this._dateRemplacementPrevue,
    this._dateRetrait,
    this._notes,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_nom.isNotEmpty, 'nom must not be empty'),
        assert(_potagerId.isNotEmpty, 'potagerId must not be empty'),
        assert(
          _dateRetrait == null || !_dateRetrait.isBefore(_dateInstallation),
          'the retirement date cannot precede the installation date',
        ),
        assert(
          _dateRemplacementPrevue == null ||
              !_dateRemplacementPrevue.isBefore(_dateInstallation),
          'the planned replacement date cannot precede the installation date',
        );

  /// Registers an equipment. Condition defaults to `bon`; a null [parcelleId]
  /// makes it transverse to the whole potager.
  factory Equipement({
    required String id,
    required String nom,
    required String potagerId,
    required TypeEquipement type,
    required DateTime dateInstallation,
    String? parcelleId,
    EtatEquipement etat = EtatEquipement.bon,
    String? marqueModele,
    DateTime? dateRemplacementPrevue,
    DateTime? dateRetrait,
    String? notes,
  }) =>
      Equipement._(
        id,
        nom,
        potagerId,
        parcelleId,
        type,
        etat,
        marqueModele,
        dateInstallation,
        dateRemplacementPrevue,
        dateRetrait,
        notes,
      );

  String get id => _id;
  String get nom => _nom;
  String get potagerId => _potagerId;
  String? get parcelleId => _parcelleId;
  TypeEquipement get type => _type;
  EtatEquipement get etat => _etat;
  String? get marqueModele => _marqueModele;
  DateTime get dateInstallation => _dateInstallation;
  DateTime? get dateRemplacementPrevue => _dateRemplacementPrevue;
  DateTime? get dateRetrait => _dateRetrait;
  String? get notes => _notes;

  /// Agronomic effect of this equipment, derived from its [type].
  EffetEquipement effet() => EffetEquipement.pourType(_type);

  /// Whether the equipment is not attached to a specific parcelle.
  bool get estTransverse => _parcelleId == null;

  /// Whether the equipment is still in service (not retired).
  bool get estEnService => _dateRetrait == null;

  /// Updates the equipment condition.
  void changerEtat(EtatEquipement etat) => _etat = etat;

  /// Sets or clears the free-text notes.
  void modifierNotes(String? notes) => _notes = notes;

  /// Retires the equipment on [date] (kept for history). [date] must not precede
  /// the installation date.
  void retirer(DateTime date) {
    assert(
      !date.isBefore(_dateInstallation),
      'the retirement date cannot precede the installation date',
    );
    _dateRetrait = date;
  }

  @override
  bool operator ==(Object other) => other is Equipement && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => 'Equipement($_id, ${_type.name}, potager: $_potagerId)';
}
