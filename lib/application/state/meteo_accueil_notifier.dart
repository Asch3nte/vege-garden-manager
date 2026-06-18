import 'package:riverpod/riverpod.dart';

import '../../domain/value_objects/donnees_meteo.dart';
import '../../domain/value_objects/prevision_meteo.dart';
import '../engine/bilan_arrosage.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import 'meteo_accueil_vue.dart';

/// Builds the home **weather card** view-model: today's conditions and a
/// garden-level watering verdict for the active garden's position.
///
/// Composition only. Needs a usable position (set via onboarding / the garden
/// form); without one it returns [MeteoAccueilVue.indisponible]. The verdict is
/// a coarse, garden-wide hint (the per-plant watering advice lives in
/// `CalculerBesoinArrosage`); it reuses the engine's rain thresholds.
class MeteoAccueilNotifier extends AsyncNotifier<MeteoAccueilVue> {
  @override
  Future<MeteoAccueilVue> build() async {
    final potager =
        await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
    if (potager == null || !potager.localisation.estDefinie) {
      return MeteoAccueilVue.indisponible();
    }

    final meteo = ref.watch(meteoServiceProvider);
    final loc = potager.localisation;
    final actuelle = await meteo.obtenirMeteoActuelle(loc);
    final previsions = await meteo.obtenirPrevisions(loc, 2);

    return MeteoAccueilVue.disponible(
      tempMin: actuelle.tempMin,
      tempMax: actuelle.tempMax,
      risqueGel: actuelle.risqueGel,
      verdict: MeteoAccueilNotifier.deriverVerdict(actuelle, previsions),
    );
  }

  /// Coarse garden-wide verdict: rain soon → wait; recent rain → moist soil;
  /// hot/dry → water; otherwise mild.
  ///
  /// Public so that [MeteoDetailNotifier] can reuse the same logic without
  /// duplicating the thresholds.
  static VerdictMeteo deriverVerdict(
    DonneesMeteo actuelle,
    List<PrevisionMeteo> previsions,
  ) {
    final pluieAVenir = previsions.any((p) =>
        p.precipitationsMm * p.probabilitePluie >= BilanArrosage.seuilScorePluie);
    if (pluieAVenir) return VerdictMeteo.pluieAVenir;
    if (actuelle.precipitationsMm >= BilanArrosage.seuilPluieRecenteMm) {
      return VerdictMeteo.solHumide;
    }
    if (actuelle.risqueCanicule || actuelle.tempMax >= 28) {
      return VerdictMeteo.arroserConseille;
    }
    return VerdictMeteo.clement;
  }
}

/// The home weather-card view-model provider.
final meteoAccueilProvider =
    AsyncNotifierProvider<MeteoAccueilNotifier, MeteoAccueilVue>(
  MeteoAccueilNotifier.new,
);
