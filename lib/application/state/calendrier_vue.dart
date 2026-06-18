import '../../domain/entities/tache.dart';

/// Window covered by the agenda: the next 7 days, or the rest of the month.
enum PorteeAgenda { semaine, mois }

/// Tasks of a single day, in display order (undone first, then by time).
class GroupeJour {
  final DateTime _jour;
  final List<Tache> _taches;

  GroupeJour._(this._jour, List<Tache> taches)
      : _taches = List.unmodifiable(taches);

  /// Creates a day group. [jour] is the local date (midnight).
  factory GroupeJour({required DateTime jour, required List<Tache> taches}) =>
      GroupeJour._(jour, taches);

  /// The day (local midnight).
  DateTime get jour => _jour;

  /// Tasks planned that day (immutable).
  List<Tache> get taches => _taches;

  /// Number of tasks still to do that day.
  int get nombreAFaire => _taches.where((t) => !t.estFaite).length;
}

/// Immutable view-model for the **Calendrier** screen.
///
/// Holds two datasets: the **agenda** day groups over the current [portee]
/// window (with the done/total counters), and the **month** day groups for the
/// displayed [moisAffiche] (the navigable monthly grid). Built by
/// `CalendrierNotifier`.
class CalendrierVue {
  final PorteeAgenda _portee;
  final List<GroupeJour> _groupes;
  final int _total;
  final int _faites;
  final DateTime _moisAffiche;
  final List<GroupeJour> _groupesMois;
  final Map<String, String> _ciblesNoms;

  CalendrierVue._(
    this._portee,
    List<GroupeJour> groupes,
    this._total,
    this._faites,
    this._moisAffiche,
    List<GroupeJour> groupesMois,
    Map<String, String> ciblesNoms,
  )   : _groupes = List.unmodifiable(groupes),
        _groupesMois = List.unmodifiable(groupesMois),
        _ciblesNoms = Map.unmodifiable(ciblesNoms);

  /// Builds the calendar view from its agenda [groupes] and the displayed
  /// month's [groupesMois]; agenda counts are derived. [ciblesNoms] maps each
  /// task target (`'<cible>:<cibleId>'`) to its resolved display name.
  factory CalendrierVue({
    required PorteeAgenda portee,
    required List<GroupeJour> groupes,
    required DateTime moisAffiche,
    required List<GroupeJour> groupesMois,
    Map<String, String> ciblesNoms = const {},
  }) {
    var total = 0;
    var faites = 0;
    for (final g in groupes) {
      total += g.taches.length;
      faites += g.taches.where((t) => t.estFaite).length;
    }
    return CalendrierVue._(
      portee,
      groupes,
      total,
      faites,
      moisAffiche,
      groupesMois,
      ciblesNoms,
    );
  }

  /// Resolved display name of a [tache]'s target (the garden, a zone or a crop),
  /// or `null` when it cannot be resolved (equipment, or a deleted target).
  String? cibleNom(Tache tache) =>
      _ciblesNoms['${tache.cible.name}:${tache.cibleId}'];

  /// Current window scope.
  PorteeAgenda get portee => _portee;

  /// Day groups, ordered by date (immutable).
  List<GroupeJour> get groupes => _groupes;

  /// First day (local midnight) of the month shown by the monthly grid.
  DateTime get moisAffiche => _moisAffiche;

  /// Day groups of the displayed month, ordered by date (immutable).
  List<GroupeJour> get groupesMois => _groupesMois;

  /// The displayed month's group for [jour], or `null` if that day is empty.
  GroupeJour? groupePourJour(DateTime jour) {
    for (final g in _groupesMois) {
      if (g.jour.year == jour.year &&
          g.jour.month == jour.month &&
          g.jour.day == jour.day) {
        return g;
      }
    }
    return null;
  }

  /// Total number of tasks in the window.
  int get total => _total;

  /// Number of completed tasks in the window.
  int get faites => _faites;

  /// Number of tasks still to do in the window.
  int get restantes => _total - _faites;

  /// Whether the window holds no task at all (drives the empty state).
  bool get vide => _total == 0;
}
