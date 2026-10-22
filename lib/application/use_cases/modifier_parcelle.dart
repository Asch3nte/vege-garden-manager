import 'package:riverpod/riverpod.dart';

import '../../domain/entities/parcelle.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../providers/repository_providers.dart';

/// Use case: save an edited parcelle.
///
/// Throws `SurfaceInsuffisanteException` when a reduced surface no longer
/// holds its active plantations.
class ModifierParcelle {
  final AbstractParcelleRepository _parcelles;
  final AbstractPlantationRepository _plantations;

  ModifierParcelle(this._parcelles, this._plantations);

  Future<void> executer(Parcelle parcelle) async {
    final stockee = await _parcelles.obtenirParId(parcelle.id);
    // An unreduced surface is saved as is, even on an already overfull zone.
    if (stockee == null || stockee.surface.depasse(parcelle.surface)) {
      parcelle.verifierContenance(
          await _plantations.obtenirParParcelle(parcelle.id));
    }
    await _parcelles.sauvegarder(parcelle);
  }
}

/// DI provider for [ModifierParcelle].
final modifierParcelleProvider = Provider<ModifierParcelle>(
  (ref) => ModifierParcelle(
    ref.watch(parcelleRepositoryProvider),
    ref.watch(plantationRepositoryProvider),
  ),
);
