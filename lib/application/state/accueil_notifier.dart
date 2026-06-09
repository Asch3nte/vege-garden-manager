import 'package:riverpod/riverpod.dart';

import '../../domain/entities/tache.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../../domain/repositories/abstract_preferences_repository.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../providers/horloge_provider.dart';
import '../providers/repository_providers.dart';
import 'accueil_vue.dart';

/// Assembles the **Accueil** dashboard view-model from the repositories.
///
/// This is the single cross-cutting read of the app: the dashboard aggregates
/// the active garden, its zones, the tasks due *today* (all zones) and the user
/// experience level. Each piece comes from an existing Domain repository — no
/// new persistence is introduced here, the notifier only composes reads.
///
/// The clock is injectable (via [AccueilNotifier.avecHorloge] in tests) so the
/// "today" window is deterministic. Weather, alerts and season harvests are
/// **not** wired yet (they need verdict logic / aggregate queries that do not
/// exist); the screen renders those as explicit "à venir" placeholders rather
/// than fabricated values.
class AccueilNotifier extends AsyncNotifier<AccueilVue> {
  @override
  Future<AccueilVue> build() async {
    final potagers = ref.watch(potagerRepositoryProvider);
    final parcelles = ref.watch(parcelleRepositoryProvider);
    final taches = ref.watch(tacheRepositoryProvider);
    final preferences = ref.watch(preferencesRepositoryProvider);
    final maintenant = ref.watch(horlogeProvider);

    return _assembler(potagers, parcelles, taches, preferences, maintenant);
  }

  Future<AccueilVue> _assembler(
    AbstractPotagerRepository potagers,
    AbstractParcelleRepository parcelles,
    AbstractTacheRepository taches,
    AbstractPreferencesRepository preferences,
    DateTime Function() maintenant,
  ) async {
    final prefs = await preferences.charger();
    final potager = await potagers.obtenirPotagerActif();

    final zones = potager == null
        ? const <ZoneApercu>[]
        : [
            for (final p in await parcelles.obtenirParPotager(potager.id))
              ZoneApercu(id: p.id, nom: p.nom),
          ];

    final debut = _debutDuJour(maintenant());
    final tachesDuJour = _trier(
      await taches.obtenirEntreDates(debut, debut.add(const Duration(days: 1))),
    );

    return AccueilVue(
      nomPotager: potager?.nom,
      niveau: prefs.niveauExperience,
      zones: zones,
      tachesDuJour: tachesDuJour,
    );
  }

  /// Start of the day (local midnight) for the task window.
  static DateTime _debutDuJour(DateTime n) => DateTime(n.year, n.month, n.day);

  /// Orders today's tasks: still-to-do before done, then by planned time.
  static List<Tache> _trier(List<Tache> taches) {
    final triees = [...taches]..sort((a, b) {
        if (a.estFaite != b.estFaite) return a.estFaite ? 1 : -1;
        return a.datePrevue.compareTo(b.datePrevue);
      });
    return triees;
  }
}

/// The Accueil dashboard view-model provider.
final accueilProvider =
    AsyncNotifierProvider<AccueilNotifier, AccueilVue>(AccueilNotifier.new);
