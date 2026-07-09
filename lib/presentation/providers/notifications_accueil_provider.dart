import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/horloge_provider.dart';
import '../../application/providers/repository_providers.dart';
import '../../application/use_cases/detecter_alertes_meteo.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/statut_plantation.dart';
import '../../domain/services/localisation_meteo.dart';
import '../../domain/value_objects/alerte_culture.dart';

/// Content of the home notifications panel (bell): the current weather alerts
/// and today's urgent, not-yet-done tasks.
class NotificationsAccueilVue {
  final List<AlerteCulture> _alertes;
  final List<Tache> _tachesUrgentes;

  NotificationsAccueilVue({
    required List<AlerteCulture> alertes,
    required List<Tache> tachesUrgentes,
  })  : _alertes = List.unmodifiable(alertes),
        _tachesUrgentes = List.unmodifiable(tachesUrgentes);

  /// Weather alerts (frost / heatwave / heavy rain) on the cultures in place.
  List<AlerteCulture> get alertes => _alertes;

  /// Today's undone urgent tasks.
  List<Tache> get tachesUrgentes => _tachesUrgentes;

  /// Total number of notifications (drives the bell badge).
  int get total => _alertes.length + _tachesUrgentes.length;

  /// Whether there is nothing to show.
  bool get estVide => total == 0;
}

/// Builds the home notifications panel view-model on demand.
///
/// Reuses the dashboard's inputs: today's tasks (filtered to urgent + undone)
/// and [DetecterAlertesMeteo] over the active garden's cultures. Respects the
/// automatic-weather opt-out (item C): with weather off, no Open-Meteo call is
/// made and the alert list is empty. Auto-disposed so it recomputes each time
/// the panel is opened.
final notificationsAccueilProvider =
    FutureProvider.autoDispose<NotificationsAccueilVue>((ref) async {
  final maintenant = ref.watch(horlogeProvider)();
  final debutJour = DateTime(maintenant.year, maintenant.month, maintenant.day);
  final finJour = debutJour.add(const Duration(days: 1));

  // Today's undone urgent tasks (all gardens, like the dashboard's task list).
  final taches = await ref
      .watch(tacheRepositoryProvider)
      .obtenirEntreDates(debutJour, finJour);
  final urgentes = taches
      .where((t) => !t.estFaite && t.priorite == PrioriteTache.urgente)
      .toList(growable: false);

  // Weather alerts on the active garden's cultures (0 without a position or
  // with automatic weather off — the use case + the effective location handle
  // both).
  var alertes = const <AlerteCulture>[];
  final potager =
      await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager != null) {
    final prefs = await ref.watch(preferencesRepositoryProvider).charger();
    final parcelles = await ref
        .watch(parcelleRepositoryProvider)
        .obtenirParPotager(potager.id);
    final plantationsRepo = ref.watch(plantationRepositoryProvider);
    final actives = <Plantation>[];
    for (final parcelle in parcelles) {
      actives.addAll((await plantationsRepo.obtenirParParcelle(parcelle.id))
          .where((p) => !p.statut.estTerminal));
    }
    alertes = await ref.read(detecterAlertesMeteoProvider).executer(
          localisation: localisationPourMeteo(potager.localisation,
              meteoAutoActive: prefs.meteoAutoActive),
          plantationsActives: actives,
        );
  }

  return NotificationsAccueilVue(alertes: alertes, tachesUrgentes: urgentes);
});
