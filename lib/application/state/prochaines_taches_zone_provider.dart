import 'package:riverpod/riverpod.dart';

import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/statut_plantation.dart';
import '../providers/repository_providers.dart';

/// The next actionable (not-done) task of each active crop in a zone, keyed by
/// plantation id. The earliest planned date wins; a crop with no pending task is
/// simply absent from the map (the UI then shows nothing for it — never an
/// invented value).
///
/// Scoped to the zone-detail screen (a `family` on the zone id) so the Potager
/// plan is not burdened with the per-crop task lookups it does not display.
/// Reads only — composes the plantation and task repositories via the
/// already-modelled `CibleTache.plantation` target.
final prochainesTachesZoneProvider =
    FutureProvider.autoDispose.family<Map<String, Tache>, String>(
  (ref, zoneId) async {
    final plantations = ref.watch(plantationRepositoryProvider);
    final taches = ref.watch(tacheRepositoryProvider);

    final result = <String, Tache>{};
    for (final plantation in await plantations.obtenirParParcelle(zoneId)) {
      if (plantation.statut.estTerminal) continue;
      final aFaire = [
        for (final t
            in await taches.obtenirParCible(CibleTache.plantation, plantation.id))
          if (!t.estFaite) t,
      ]..sort((a, b) => a.datePrevue.compareTo(b.datePrevue));
      if (aFaire.isNotEmpty) result[plantation.id] = aFaire.first;
    }
    return result;
  },
);
