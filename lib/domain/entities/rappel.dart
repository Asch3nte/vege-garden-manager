import '../enums/cible_tache.dart';
import '../enums/etat_rappel.dart';
import '../enums/jour_semaine.dart';
import '../enums/priorite_tache.dart';
import '../enums/type_recurrence.dart';
import '../enums/type_tache.dart';
import 'tache.dart';

/// A planning rule that generates tasks. A reminder can be one-off or recurring.
///
/// Distinction with `Tache`: a `Rappel` is a *rule*; each occurrence it produces
/// is a separate `Tache` (linked back via `rappelOrigineId`).
///
/// `Rappel` is an **entity** (identity by [id]); the [id] is a UUID generated
/// app-side and injected. Domain names are kept in French; the code is
/// documented in English. See `docs/05-modele-de-domaine.md` §3.7.
class Rappel {
  final String _id;
  String _titre;
  String? _description;
  final TypeTache _typeTacheGeneree;
  PrioriteTache _priorite;
  final CibleTache _cible;
  final String _cibleId;
  final DateTime _dateDebut;
  DateTime? _dateFin;
  final TypeRecurrence _typeRecurrence;
  final int? _intervalleJours;
  final Set<JourSemaine> _joursSemaine;
  final int? _jourDuMois;
  EtatRappel _etat;
  int _genererXJoursAvance;
  String? _notes;

  Rappel._(
    this._id,
    this._titre,
    this._description,
    this._typeTacheGeneree,
    this._priorite,
    this._cible,
    this._cibleId,
    this._dateDebut,
    this._dateFin,
    this._typeRecurrence,
    this._intervalleJours,
    this._joursSemaine,
    this._jourDuMois,
    this._etat,
    this._genererXJoursAvance,
    this._notes,
  )   : assert(_id.isNotEmpty, 'id must not be empty'),
        assert(_titre.isNotEmpty, 'titre must not be empty'),
        assert(_cibleId.isNotEmpty, 'cibleId must not be empty'),
        assert(
          _dateFin == null || !_dateFin.isBefore(_dateDebut),
          'dateFin cannot precede dateDebut',
        ),
        assert(
          _genererXJoursAvance >= 0 && _genererXJoursAvance <= 365,
          'genererXJoursAvance must be in 0..365',
        ),
        assert(
          _typeRecurrence != TypeRecurrence.personnalise ||
              (_intervalleJours != null && _intervalleJours > 0),
          'a custom recurrence requires a positive interval',
        ),
        assert(
          _typeRecurrence != TypeRecurrence.hebdomadaire ||
              _joursSemaine.isNotEmpty,
          'a weekly recurrence requires at least one weekday',
        ),
        assert(
          _typeRecurrence != TypeRecurrence.mensuel ||
              (_jourDuMois != null && _jourDuMois >= 1 && _jourDuMois <= 31),
          'a monthly recurrence requires a day of month in 1..31',
        );

  /// Creates a reminder. Defaults to an active reminder generating tasks 7 days
  /// ahead. Recurrence parameters are required according to [typeRecurrence].
  factory Rappel({
    required String id,
    required String titre,
    required TypeTache typeTacheGeneree,
    required CibleTache cible,
    required String cibleId,
    required DateTime dateDebut,
    required TypeRecurrence typeRecurrence,
    String? description,
    PrioriteTache priorite = PrioriteTache.normale,
    DateTime? dateFin,
    int? intervalleJours,
    Set<JourSemaine>? joursSemaine,
    int? jourDuMois,
    EtatRappel etat = EtatRappel.actif,
    int genererXJoursAvance = 7,
    String? notes,
  }) =>
      Rappel._(
        id,
        titre,
        description,
        typeTacheGeneree,
        priorite,
        cible,
        cibleId,
        dateDebut,
        dateFin,
        typeRecurrence,
        intervalleJours,
        Set<JourSemaine>.of(joursSemaine ?? const <JourSemaine>{}),
        jourDuMois,
        etat,
        genererXJoursAvance,
        notes,
      );

  String get id => _id;
  String get titre => _titre;
  String? get description => _description;
  TypeTache get typeTacheGeneree => _typeTacheGeneree;
  PrioriteTache get priorite => _priorite;
  CibleTache get cible => _cible;
  String get cibleId => _cibleId;
  DateTime get dateDebut => _dateDebut;
  DateTime? get dateFin => _dateFin;
  TypeRecurrence get typeRecurrence => _typeRecurrence;
  int? get intervalleJours => _intervalleJours;
  Set<JourSemaine> get joursSemaine => Set.unmodifiable(_joursSemaine);
  int? get jourDuMois => _jourDuMois;
  EtatRappel get etat => _etat;
  int get genererXJoursAvance => _genererXJoursAvance;
  String? get notes => _notes;

  static DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The next occurrence strictly after [apres], or `null` when there is none
  /// (paused/finished reminder, one-off already passed, or beyond [dateFin]).
  DateTime? prochaineRecurrence(DateTime apres) {
    if (_etat != EtatRappel.actif) return null;
    final debut = _jour(_dateDebut);
    final apresJour = _jour(apres);

    DateTime? candidat;
    switch (_typeRecurrence) {
      case TypeRecurrence.ponctuel:
        candidat = debut.isAfter(apresJour) ? debut : null;
      case TypeRecurrence.personnalise:
        final interval = _intervalleJours!;
        if (apresJour.isBefore(debut)) {
          candidat = debut;
        } else {
          final k = (apresJour.difference(debut).inDays ~/ interval) + 1;
          // Built via the constructor (not Duration) to stay DST-safe.
          candidat = DateTime(debut.year, debut.month, debut.day + k * interval);
        }
      case TypeRecurrence.quotidien:
      case TypeRecurrence.hebdomadaire:
      case TypeRecurrence.mensuel:
        final from = debut.isAfter(apresJour)
            ? debut
            : DateTime(apresJour.year, apresJour.month, apresJour.day + 1);
        candidat = _premierJourCorrespondant(from);
    }

    if (candidat == null) return null;
    if (_dateFin != null && candidat.isAfter(_jour(_dateFin!))) return null;
    return candidat;
  }

  DateTime? _premierJourCorrespondant(DateTime from) {
    final capJours =
        _dateFin != null ? _jour(_dateFin!).difference(from).inDays : 400;
    for (var i = 0; i <= capJours; i++) {
      // Built via the constructor (which normalises day overflow) to stay
      // DST-safe and always land on midnight.
      final d = DateTime(from.year, from.month, from.day + i);
      if (_correspond(d)) return d;
    }
    return null;
  }

  bool _correspond(DateTime d) => switch (_typeRecurrence) {
        TypeRecurrence.quotidien => true,
        TypeRecurrence.hebdomadaire => _joursSemaine.contains(d.jourSemaine),
        TypeRecurrence.mensuel => d.day == _jourDuMois,
        _ => false,
      };

  /// Builds a concrete [Tache] for a given occurrence [datePrevue], carrying the
  /// reminder's target, type and priority, and linking back via
  /// `rappelOrigineId`.
  Tache genererTache({required String id, required DateTime datePrevue}) =>
      Tache(
        id: id,
        titre: _titre,
        description: _description,
        type: _typeTacheGeneree,
        cible: _cible,
        cibleId: _cibleId,
        datePrevue: datePrevue,
        priorite: _priorite,
        rappelOrigineId: _id,
      );

  void mettreEnPause() => _etat = EtatRappel.enPause;
  void reactiver() => _etat = EtatRappel.actif;
  void terminer() => _etat = EtatRappel.termine;

  void changerPriorite(PrioriteTache priorite) => _priorite = priorite;

  void definirHorizonGeneration(int jours) {
    assert(jours >= 0 && jours <= 365, 'horizon must be in 0..365');
    _genererXJoursAvance = jours;
  }

  void modifierDateFin(DateTime? dateFin) {
    assert(
      dateFin == null || !dateFin.isBefore(_dateDebut),
      'dateFin cannot precede dateDebut',
    );
    _dateFin = dateFin;
  }

  void renommer(String titre) {
    assert(titre.isNotEmpty, 'titre must not be empty');
    _titre = titre;
  }

  void modifierNotes(String? notes) => _notes = notes;

  @override
  bool operator ==(Object other) => other is Rappel && other._id == _id;

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() =>
      'Rappel($_id, ${_typeRecurrence.name}, ${_etat.name})';
}
