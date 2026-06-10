import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/value_objects/prevision_horaire.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';

/// Hourly forecast for the active garden's position (weather detail view).
///
/// Returns an empty list when there is no usable position; throws (surfaced as
/// an error state) when the weather service is unavailable. Fetched live — the
/// detail view is opened on demand.
final meteoHoraireProvider = FutureProvider<List<PrevisionHoraire>>((ref) async {
  final potager =
      await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
  if (potager == null || !potager.localisation.estDefinie) {
    return const <PrevisionHoraire>[];
  }
  return ref
      .watch(meteoServiceProvider)
      .obtenirPrevisionsHoraires(potager.localisation, nbJours: 3);
});
