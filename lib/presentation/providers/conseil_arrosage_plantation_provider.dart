import 'package:riverpod/riverpod.dart';

import '../../application/providers/repository_providers.dart';
import '../../application/state/preferences_notifier.dart';
import '../../application/use_cases/calculer_besoin_arrosage.dart';
import '../../domain/value_objects/conseil_arrosage.dart';

/// Per-plantation watering advice, derived on demand (auto-dispose).
///
/// The parameter is the `plantationId`. Returns `null` when:
/// - the plantation id is unknown (removed),
/// - there is no active garden,
/// - the plant has no catalogue entry.
///
/// Errors from the weather service or the database are absorbed (the advice
/// falls back to demand-only or to null) — a watering badge is non-critical.
///
/// The provider is auto-disposed when its last listener unsubscribes (one
/// instance per visible crop row).
final conseilArrosagePlantationProvider =
    FutureProvider.autoDispose.family<ConseilArrosage?, String>(
  (ref, plantationId) async {
    final plantation = await ref
        .watch(plantationRepositoryProvider)
        .obtenirParId(plantationId);
    if (plantation == null) return null;

    final potager =
        await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
    if (potager == null) return null;

    // Honour the auto weather-fetch opt-out (docs/11): with it off, the advice
    // degrades to demand-only rather than hitting Open-Meteo automatically.
    final meteoAuto =
        ref.watch(preferencesProvider).value?.meteoAutoActive ?? true;

    final useCase =
        await ref.watch(calculerBesoinArrosageProvider.future);
    return useCase.executer(
      plantation: plantation,
      localisation: potager.localisation,
      meteoAutoActive: meteoAuto,
    );
  },
);
