import '../enums/cible_tache.dart';
import '../enums/etat_tache.dart';
import '../enums/priorite_tache.dart';
import '../enums/type_tache.dart';

/// A concrete, single action to carry out (or already done) on a polymorphic
/// target: a potager, parcelle, plantation or equipment.
///
/// A task may originate from a [rappelOrigineId] (a recurring `Rappel` that
/// generated it). `Tache` is an **entity** (identity by [id]); the [id] is a
/// UUID generated app-side and injected.
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §3.6.
class Tache {
  final String _id;
  String _titre;
  String? _description;
  final TypeTache _type;
  EtatTache _etat;
  PrioriteTache _priorite;
  final CibleTache _cible;
  final String _cibleId;
  DateTime _datePrevue;
  DateTime? _dateRealisation;
  int? _dureeReelleMinutes;
  final String? _rappelOrigineId;
  String? _notes;

  Tache._(
    this._id,
    this._titre,
    this._description,
    this._type,
    this._etat,
    this._priorite,
    this._cible,
    this._cibleId,
    this._datePrevue,
    this._dateRealisation,
    this._dureeReelleMinutes,
    this._rappelOrigineId,
    this._notes,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_titre.isNotEmpty, 'titre must not be empty'),
        assert(_cibleId.isNotEmpty, 'cibleId must not be empty'),
        assert(
          _etat != EtatTache.terminee || _dateRealisation != null,
          'a completed task must have a completion date',
        ),
        assert(
          _dureeReelleMinutes == null || _dureeReelleMinutes > 0,
          'duration, when set, must be > 0',
        );

  /// Creates a task. Defaults to a normal-priority, to-do task.
  factory Tache({
    required String id,
    required String titre,
    required TypeTache type,
    required CibleTache cible,
    required String cibleId,
    required DateTime datePrevue,
    String? description,
    EtatTache etat = EtatTache.aFaire,
    PrioriteTache priorite = PrioriteTache.normale,
    DateTime? dateRealisation,
    int? dureeReelleMinutes,
    String? rappelOrigineId,
    String? notes,
  }) =>
      Tache._(
        id,
        titre,
        description,
        type,
        etat,
        priorite,
        cible,
        cibleId,
        datePrevue,
        dateRealisation,
        dureeReelleMinutes,
        rappelOrigineId,
        notes,
      );

  String get id => _id;
  String get titre => _titre;
  String? get description => _description;
  TypeTache get type => _type;
  EtatTache get etat => _etat;
  PrioriteTache get priorite => _priorite;
  CibleTache get cible => _cible;
  String get cibleId => _cibleId;
  DateTime get datePrevue => _datePrevue;
  DateTime? get dateRealisation => _dateRealisation;
  int? get dureeReelleMinutes => _dureeReelleMinutes;

  /// Id of the reminder that generated this task, when applicable.
  String? get rappelOrigineId => _rappelOrigineId;
  String? get notes => _notes;

  /// Whether the task is done.
  bool get estFaite => _etat == EtatTache.terminee;

  /// Marks the task in progress.
  void demarrer() => _etat = EtatTache.enCours;

  /// Marks the task done on [date], optionally recording the time spent.
  void marquerFaite(DateTime date, {int? dureeMinutes}) {
    assert(
      dureeMinutes == null || dureeMinutes > 0,
      'duration, when set, must be > 0',
    );
    _etat = EtatTache.terminee;
    _dateRealisation = date;
    _dureeReelleMinutes = dureeMinutes;
  }

  /// Reschedules the task to [nouvelleDatePrevue], resetting it to to-do.
  void reporter(DateTime nouvelleDatePrevue) {
    _datePrevue = nouvelleDatePrevue;
    _etat = EtatTache.aFaire;
    _dateRealisation = null;
    _dureeReelleMinutes = null;
  }

  /// Cancels the task.
  void annuler() => _etat = EtatTache.annulee;

  void changerPriorite(PrioriteTache priorite) => _priorite = priorite;

  void renommer(String titre) {
    assert(titre.isNotEmpty, 'titre must not be empty');
    _titre = titre;
  }

  void modifierNotes(String? notes) => _notes = notes;

  @override
  bool operator ==(Object other) => other is Tache && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() =>
      'Tache($_id, ${_type.name}, ${_etat.name}, ${_cible.name}:$_cibleId)';
}
