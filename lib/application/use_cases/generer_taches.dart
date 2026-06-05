import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/tache.dart';
import '../../domain/repositories/abstract_rappel_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../providers/repository_providers.dart';

/// Engine use case: materialise the tasks due from the active reminders.
///
/// For each active reminder, it enumerates the occurrences of
/// `Rappel.prochaineRecurrence` falling within `[today, today + horizon]` (the
/// reminder's own `genererXJoursAvance`) and creates one `Tache` per occurrence
/// via `Rappel.genererTache`.
///
/// **Strict deduplication**: a `(rappelOrigineId, datePrevue)` pair is never
/// materialised twice. The check is made against **every** existing task of the
/// reminder regardless of its state — so a task the user cancelled (or already
/// completed) never reappears on a later run. The dedup key is the planned
/// instant normalised to UTC ISO-8601, which round-trips identically through the
/// repository (no timezone/day-boundary ambiguity).
///
/// Occurrences strictly in the past (before today) are not generated.
///
/// The id generator and the clock are injectable so generation is deterministic
/// under test.
class GenererTaches {
  final AbstractRappelRepository _rappels;
  final AbstractTacheRepository _taches;
  final String Function() _genererId;
  final DateTime Function() _maintenant;

  GenererTaches(
    this._rappels,
    this._taches, {
    String Function()? genererId,
    DateTime Function()? maintenant,
  })  : _genererId = genererId ?? _uuid,
        _maintenant = maintenant ?? DateTime.now;

  static String _uuid() => const Uuid().v4();

  /// Generates and persists the due tasks. Returns the tasks created on this run
  /// (already-existing occurrences are skipped and not returned).
  Future<List<Tache>> executer() async {
    final aujourdhui = _jour(_maintenant());
    final rappels = await _rappels.obtenirActifs();
    final creees = <Tache>[];

    for (final rappel in rappels) {
      final limite = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day + rappel.genererXJoursAvance,
      );
      // Existing occurrences of this reminder, any state (incl. cancelled).
      final dejaPresentes = (await _taches.obtenirParRappel(rappel.id))
          .map((t) => _cle(t.datePrevue))
          .toSet();

      // Start the cursor on the day before today so that an occurrence falling
      // exactly today is included (prochaineRecurrence is "strictly after").
      var curseur = DateTime(
        aujourdhui.year,
        aujourdhui.month,
        aujourdhui.day - 1,
      );
      while (true) {
        final prochaine = rappel.prochaineRecurrence(curseur);
        if (prochaine == null || prochaine.isAfter(limite)) break;
        curseur = prochaine;
        if (dejaPresentes.add(_cle(prochaine))) {
          final tache =
              rappel.genererTache(id: _genererId(), datePrevue: prochaine);
          await _taches.sauvegarder(tache);
          creees.add(tache);
        }
      }
    }
    return creees;
  }

  static DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Dedup key: the planned instant normalised to UTC ISO-8601 (matches how the
  /// repository stores and re-reads `datePrevue`).
  static String _cle(DateTime datePrevue) =>
      datePrevue.toUtc().toIso8601String();
}

/// DI provider for [GenererTaches].
final genererTachesProvider = Provider<GenererTaches>(
  (ref) => GenererTaches(
    ref.watch(rappelRepositoryProvider),
    ref.watch(tacheRepositoryProvider),
  ),
);
