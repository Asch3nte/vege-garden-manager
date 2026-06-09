import 'package:riverpod/riverpod.dart';

import '../../domain/entities/tache.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../providers/horloge_provider.dart';
import '../providers/repository_providers.dart';
import 'calendrier_vue.dart';

/// Drives the **Calendrier** agenda: the tasks over the current window
/// ([PorteeAgenda]), grouped by day, with the action to tick a task off.
///
/// Reads come from [AbstractTacheRepository.obtenirEntreDates]; ticking a task
/// uses the domain's `Tache.marquerFaite` then persists via the repository.
/// Reopening a completed task is **not** offered — the domain has no plain
/// "reopen" transition (only `reporter`, which reschedules); see docs/15.
class CalendrierNotifier extends AsyncNotifier<CalendrierVue> {
  PorteeAgenda _portee = PorteeAgenda.semaine;

  @override
  Future<CalendrierVue> build() async {
    final taches = ref.watch(tacheRepositoryProvider);
    final maintenant = ref.watch(horlogeProvider);
    return _assembler(taches, maintenant);
  }

  /// Switches the window scope (week / month) and reloads.
  Future<void> definirPortee(PorteeAgenda portee) async {
    if (portee == _portee) return;
    _portee = portee;
    await _recharger();
  }

  /// Marks [tache] done now and persists it, then reloads the agenda.
  Future<void> cocher(Tache tache) async {
    if (tache.estFaite) return;
    final maintenant = ref.read(horlogeProvider);
    tache.marquerFaite(maintenant());
    await ref.read(tacheRepositoryProvider).sauvegarder(tache);
    await _recharger();
  }

  Future<void> _recharger() async {
    final taches = ref.read(tacheRepositoryProvider);
    final maintenant = ref.read(horlogeProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _assembler(taches, maintenant));
  }

  Future<CalendrierVue> _assembler(
    AbstractTacheRepository taches,
    DateTime Function() maintenant,
  ) async {
    final debut = _minuit(maintenant());
    final fin = _finFenetre(debut);

    final liste = await taches.obtenirEntreDates(debut, fin);
    return CalendrierVue(portee: _portee, groupes: _grouperParJour(liste));
  }

  /// Exclusive end of the window: +7 days (week) or first day of next month.
  DateTime _finFenetre(DateTime debut) {
    return switch (_portee) {
      PorteeAgenda.semaine => debut.add(const Duration(days: 7)),
      PorteeAgenda.mois => DateTime(debut.year, debut.month + 1, 1),
    };
  }

  /// Groups tasks by local day, ordered by day then (undone first, by time).
  static List<GroupeJour> _grouperParJour(List<Tache> taches) {
    final parJour = <DateTime, List<Tache>>{};
    for (final t in taches) {
      final jour = _minuit(t.datePrevue);
      parJour.putIfAbsent(jour, () => []).add(t);
    }

    final jours = parJour.keys.toList()..sort();
    return [
      for (final jour in jours)
        GroupeJour(
          jour: jour,
          taches: parJour[jour]!
            ..sort((a, b) {
              if (a.estFaite != b.estFaite) return a.estFaite ? 1 : -1;
              return a.datePrevue.compareTo(b.datePrevue);
            }),
        ),
    ];
  }

  /// Local midnight of [d].
  static DateTime _minuit(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// The Calendrier agenda view-model provider.
final calendrierProvider =
    AsyncNotifierProvider<CalendrierNotifier, CalendrierVue>(
  CalendrierNotifier.new,
);
