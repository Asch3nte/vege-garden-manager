import 'package:riverpod/riverpod.dart';

import '../../core/constants/constantes_moteur.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/exceptions/meteo_indisponible_exception.dart';
import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/value_objects/alerte_culture.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/prevision_meteo.dart';
import '../engine/evaluateur_alertes_meteo.dart';
import '../providers/service_providers.dart';

/// Engine use case: detect weather alerts impacting the cultures in place.
///
/// Fetches the forecast at [Localisation] over the next `nbJours` days and
/// flags the risky days via [EvaluateurAlertesMeteo]. Each alert is **generic**
/// in V1: it concerns every plantation in place (no per-plant sensitivity data
/// exists yet — see `docs/13` §2.1).
///
/// Returns an empty list when there is nothing to alert about: the location is
/// undefined (geolocation opt-out → no weather), there is no culture in place,
/// or the weather is unavailable offline. The caller resolves which plantations
/// are in place and the potager's location.
class DetecterAlertesMeteo {
  final AbstractMeteoService _meteo;
  final EvaluateurAlertesMeteo _evaluateur;

  DetecterAlertesMeteo(this._meteo, this._evaluateur);

  Future<List<AlerteCulture>> executer({
    required Localisation localisation,
    required List<Plantation> plantationsActives,
    int nbJours = SeuilsMeteo.horizonAlertesJours,
  }) async {
    if (!localisation.estDefinie || plantationsActives.isEmpty) {
      return const <AlerteCulture>[];
    }

    final List<PrevisionMeteo> previsions;
    try {
      previsions = await _meteo.obtenirPrevisions(localisation, nbJours);
    } on MeteoIndisponibleException {
      return const <AlerteCulture>[]; // degraded: no alerts rather than failing
    }

    final ids = plantationsActives.map((p) => p.id).toList(growable: false);
    return _evaluateur
        .evaluer(previsions)
        .map((risque) => AlerteCulture(
              type: risque.type,
              date: risque.date,
              valeurDeclenchante: risque.valeur,
              plantationsConcernees: ids,
            ))
        .toList();
  }
}

/// DI provider for [DetecterAlertesMeteo].
final detecterAlertesMeteoProvider = Provider<DetecterAlertesMeteo>(
  (ref) => DetecterAlertesMeteo(
    ref.watch(meteoServiceProvider),
    ref.watch(evaluateurAlertesMeteoProvider),
  ),
);
