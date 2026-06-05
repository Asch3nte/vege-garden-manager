import 'package:riverpod/riverpod.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/value_objects/estimation_recolte.dart';
import '../engine/calculateur_dates_culture.dart';
import '../providers/repository_providers.dart';

/// Use case: estimate the harvest window of a plantation.
///
/// Looks up the plant sheet referenced by `plantation.planteId` in the
/// catalogue, then delegates the arithmetic to [CalculateurDatesCulture].
/// Returns `null` when the catalogue has no sheet for that plant.
class EstimerRecolte {
  final AbstractFichePlanteRepository _fiches;
  final CalculateurDatesCulture _calculateur;

  EstimerRecolte(this._fiches, this._calculateur);

  Future<EstimationRecolte?> executer(Plantation plantation) async {
    final fiche = await _fiches.obtenirParId(plantation.planteId);
    if (fiche == null) return null;
    return _calculateur.estimerRecolte(plantation, fiche);
  }
}

/// DI provider for [EstimerRecolte]. Async because the catalogue repository is
/// loaded from YAML assets.
final estimerRecolteProvider = FutureProvider<EstimerRecolte>(
  (ref) async => EstimerRecolte(
    await ref.watch(fichePlanteRepositoryProvider.future),
    ref.watch(calculateurDatesCultureProvider),
  ),
);
