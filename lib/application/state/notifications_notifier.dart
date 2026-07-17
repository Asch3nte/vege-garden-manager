import 'package:riverpod/riverpod.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/enums/statut_plantation.dart';
import '../../domain/value_objects/alerte_culture.dart';
import '../providers/repository_providers.dart';
import '../use_cases/detecter_alertes_meteo.dart';

/// Active weather alerts (frost / heatwave / heavy rain) raised against the
/// **in-place** cultures of the active garden, over the alert horizon.
///
/// This is the single source of truth for the app's weather-alert inbox: both
/// the dashboard alert count (`AccueilVue.nombreAlertes`) and the notifications
/// screen ([EcranNotifications]) read it, so the bell badge and the list can
/// never disagree.
///
/// Returns an empty list — without any forecast fetch — when the auto-weather
/// opt-out is off ([PreferencesUtilisateur.meteoAutoActive] false), when there
/// is no active garden, or (via [DetecterAlertesMeteo]) when the garden has no
/// position, no in-place culture, or the weather is unavailable offline.
final alertesMeteoProvider = FutureProvider<List<AlerteCulture>>((ref) async {
  final prefs = await ref.watch(preferencesRepositoryProvider).charger();
  // Auto-weather opt-out: never reach the network, report nothing.
  if (!prefs.meteoAutoActive) return const <AlerteCulture>[];

  final potager =
      await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager == null) return const <AlerteCulture>[];

  final parcelles =
      await ref.watch(parcelleRepositoryProvider).obtenirParPotager(potager.id);
  final plantationsRepo = ref.watch(plantationRepositoryProvider);
  final actives = <Plantation>[];
  for (final parcelle in parcelles) {
    for (final p in await plantationsRepo.obtenirParParcelle(parcelle.id)) {
      if (!p.statut.estTerminal) actives.add(p);
    }
  }

  // The use case degrades gracefully (no position / no culture / offline → []).
  return ref.read(detecterAlertesMeteoProvider).executer(
        localisation: potager.localisation,
        plantationsActives: actives,
      );
});
