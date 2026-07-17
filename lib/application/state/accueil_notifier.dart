import 'package:riverpod/riverpod.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/entities/tache.dart';
import '../providers/horloge_provider.dart';
import '../providers/repository_providers.dart';
import '../use_cases/generer_taches_arrosage.dart';
import 'accueil_vue.dart';
import 'notifications_notifier.dart';

/// Assembles the **Accueil** dashboard view-model from the repositories.
///
/// This is the single cross-cutting read of the app: the dashboard aggregates
/// the active garden, its zones, the tasks due *today* (all zones) and the user
/// experience level. Each piece comes from an existing Domain repository — no
/// new persistence is introduced here, the notifier only composes reads.
///
/// The clock is injectable (overridable in tests) so the "today" window is
/// deterministic. The active weather-alert count comes from the shared
/// [alertesMeteoProvider] (same source as the notifications screen, so the bell
/// badge and the alert list never disagree); the season-harvest count is
/// aggregated from the recolte repository. Live weather still renders from its
/// own [meteoAccueilProvider].
class AccueilNotifier extends AsyncNotifier<AccueilVue> {
  @override
  Future<AccueilVue> build() async {
    final prefs = await ref.watch(preferencesRepositoryProvider).charger();
    final potager =
        await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
    final maintenant = ref.watch(horlogeProvider);

    if (potager == null) {
      return AccueilVue(
        nomPotager: null,
        niveau: prefs.niveauExperience,
        zones: const [],
        tachesDuJour: await _tachesDuJour(maintenant),
      );
    }

    final parcelles =
        await ref.watch(parcelleRepositoryProvider).obtenirParPotager(potager.id);
    final plantationsRepo = ref.watch(plantationRepositoryProvider);
    final toutesPlantations = <Plantation>[];
    for (final parcelle in parcelles) {
      toutesPlantations.addAll(await plantationsRepo.obtenirParParcelle(parcelle.id));
    }

    // Generate watering tasks before querying today's tasks so they appear immediately.
    // ref.read() — one-shot action, must not create a reactive dependency.
    final generateur = await ref.read(genererTachesArrosageProvider.future);
    await generateur.executer();

    return AccueilVue(
      nomPotager: potager.nom,
      niveau: prefs.niveauExperience,
      zones: [for (final p in parcelles) ZoneApercu(id: p.id, nom: p.nom)],
      tachesDuJour: await _tachesDuJour(maintenant),
      // Same source as the notifications screen (single truth: badge == list).
      nombreAlertes: (await ref.watch(alertesMeteoProvider.future)).length,
      nombreRecoltesSaison:
          await _compterRecoltes(toutesPlantations, maintenant().year),
    );
  }

  /// Toggles [tache]'s completion (check ↔ uncheck), persists it and reloads
  /// the dashboard so the change shows immediately.
  Future<void> basculerTache(Tache tache) async {
    if (tache.estFaite) {
      tache.rouvrir();
    } else {
      tache.marquerFaite(ref.read(horlogeProvider)());
    }
    await ref.read(tacheRepositoryProvider).sauvegarder(tache);
    ref.invalidateSelf();
  }

  /// Today's tasks across the whole garden, ordered (undone first).
  Future<List<Tache>> _tachesDuJour(DateTime Function() maintenant) async {
    final debut = _debutDuJour(maintenant());
    return _trier(
      await ref
          .read(tacheRepositoryProvider)
          .obtenirEntreDates(debut, debut.add(const Duration(days: 1))),
    );
  }

  /// Number of harvests recorded during [annee] across the garden's plantations.
  Future<int> _compterRecoltes(List<Plantation> toutes, int annee) async {
    final recoltes = ref.read(recolteRepositoryProvider);
    var total = 0;
    for (final plantation in toutes) {
      for (final r in await recoltes.obtenirParPlantation(plantation.id)) {
        if (r.date.year == annee) total++;
      }
    }
    return total;
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
