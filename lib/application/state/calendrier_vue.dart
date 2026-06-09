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

/// Immutable view-model for the **Calendrier** agenda view.
///
/// Holds the day groups over the current [portee] window plus the done/total
/// counters shown in the summary. Built by `CalendrierNotifier`.
class CalendrierVue {
  final PorteeAgenda _portee;
  final List<GroupeJour> _groupes;
  final int _total;
  final int _faites;

  CalendrierVue._(this._portee, List<GroupeJour> groupes, this._total, this._faites)
      : _groupes = List.unmodifiable(groupes);

  /// Builds the agenda view from its day [groupes]; counts are derived.
  factory CalendrierVue({
    required PorteeAgenda portee,
    required List<GroupeJour> groupes,
  }) {
    var total = 0;
    var faites = 0;
    for (final g in groupes) {
      total += g.taches.length;
      faites += g.taches.where((t) => t.estFaite).length;
    }
    return CalendrierVue._(portee, groupes, total, faites);
  }

  /// Current window scope.
  PorteeAgenda get portee => _portee;

  /// Day groups, ordered by date (immutable).
  List<GroupeJour> get groupes => _groupes;

  /// Total number of tasks in the window.
  int get total => _total;

  /// Number of completed tasks in the window.
  int get faites => _faites;

  /// Number of tasks still to do in the window.
  int get restantes => _total - _faites;

  /// Whether the window holds no task at all (drives the empty state).
  bool get vide => _total == 0;
}
