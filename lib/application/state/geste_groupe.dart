import '../../domain/entities/tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_tache.dart';

/// All the tasks of one **gesture type on one day**, presented as a single
/// actionable unit.
///
/// The domain deliberately keeps one [Tache] per target: "water the tomatoes"
/// is what carries the target, the priority and the completion history, and it
/// is what the user ticks off when *that* crop is watered. But a day watering
/// five crops should read as one line, not five. This value object is that
/// presentation unit — it **aggregates without owning**: the underlying tasks
/// are untouched, and ticking the group is just ticking each of them.
///
/// Built by [grouper] and consumed by both the Accueil dashboard and the
/// Calendrier agenda so the two surfaces never diverge.
class GesteGroupe {
  final TypeTache _type;
  final DateTime _jour;
  final List<Tache> _taches;

  GesteGroupe._(this._type, this._jour, List<Tache> taches)
      : _taches = List.unmodifiable(taches),
        assert(taches.isNotEmpty, 'a gesture group holds at least one task');

  /// The gesture shared by every task of the group.
  TypeTache get type => _type;

  /// The day (local midnight) the group is planned on.
  DateTime get jour => _jour;

  /// The grouped tasks, still-to-do first then by planned time (immutable).
  List<Tache> get taches => _taches;

  /// Number of grouped tasks.
  int get nombre => _taches.length;

  /// Whether the group holds a single task — the UI then renders a plain task
  /// row rather than an expandable group.
  bool get estSeule => _taches.length == 1;

  /// The only task of a single-task group.
  ///
  /// Throws a [StateError] when the group holds several tasks: read [taches].
  Tache get tacheUnique {
    if (!estSeule) {
      throw StateError('tacheUnique on a group of $nombre tasks');
    }
    return _taches.first;
  }

  /// The grouped tasks still to do (immutable) — what "tick the whole group"
  /// acts on.
  List<Tache> get tachesAFaire =>
      List.unmodifiable(_taches.where((t) => !t.estFaite));

  /// Number of grouped tasks already done.
  int get nombreFaites => _taches.where((t) => t.estFaite).length;

  /// Whether every grouped task is done.
  bool get toutesFaites => nombreFaites == _taches.length;

  /// Whether no grouped task is done yet.
  bool get aucuneFaite => nombreFaites == 0;

  /// Whether *some* — not all — grouped tasks are done: the group checkbox
  /// renders as indeterminate.
  bool get partiellementFaite => !toutesFaites && !aucuneFaite;

  /// The group's priority: the **highest** among its tasks, so one urgent crop
  /// keeps the whole line urgent.
  PrioriteTache get priorite => _taches
      .map((t) => t.priorite)
      .reduce((a, b) => a.index >= b.index ? a : b);

  /// Earliest planned instant in the group — its position in the day.
  DateTime get premierInstant => _taches
      .map((t) => t.datePrevue)
      .reduce((a, b) => a.isBefore(b) ? a : b);

  /// Groups [taches] by `(local day, gesture type)`.
  ///
  /// Ordering is stable and mirrors the flat task list it replaces: groups with
  /// work left come first, then the earliest planned instant, then the
  /// [TypeTache] declaration order as a tie-break. Inside a group, tasks still
  /// to do come first, then by planned time.
  static List<GesteGroupe> grouper(Iterable<Tache> taches) {
    final parCle = <({DateTime jour, TypeTache type}), List<Tache>>{};
    for (final t in taches) {
      final cle = (jour: _minuit(t.datePrevue), type: t.type);
      parCle.putIfAbsent(cle, () => []).add(t);
    }

    final groupes = [
      for (final entree in parCle.entries)
        GesteGroupe._(
          entree.key.type,
          entree.key.jour,
          entree.value
            ..sort((a, b) {
              if (a.estFaite != b.estFaite) return a.estFaite ? 1 : -1;
              return a.datePrevue.compareTo(b.datePrevue);
            }),
        ),
    ];

    groupes.sort((a, b) {
      if (a.jour != b.jour) return a.jour.compareTo(b.jour);
      if (a.toutesFaites != b.toutesFaites) return a.toutesFaites ? 1 : -1;
      final parInstant = a.premierInstant.compareTo(b.premierInstant);
      if (parInstant != 0) return parInstant;
      return a.type.index.compareTo(b.type.index);
    });
    return groupes;
  }

  /// Local midnight of [d].
  static DateTime _minuit(DateTime d) => DateTime(d.year, d.month, d.day);
}
