import 'package:riverpod/riverpod.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/value_objects/surface.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_plantation.dart';

/// Exposes the plantations of a given parcelle and the actions that mutate them.
///
/// Family-scoped by `parcelleId`.
class PlantationsNotifier extends AsyncNotifier<List<Plantation>> {
  PlantationsNotifier(this.parcelleId);

  /// The parcelle whose plantations this notifier exposes (family argument).
  final String parcelleId;

  @override
  Future<List<Plantation>> build() {
    return ref
        .watch(plantationRepositoryProvider)
        .obtenirParParcelle(parcelleId);
  }

  Future<Plantation> creer({
    required String planteId,
    required DateTime dateMiseEnPlace,
    required MethodeMiseEnPlace methode,
    required Surface surfaceOccupee,
    required int nombrePieds,
  }) async {
    final plantation = await ref.read(creerPlantationProvider).executer(
          planteId: planteId,
          parcelleId: parcelleId,
          dateMiseEnPlace: dateMiseEnPlace,
          methode: methode,
          surfaceOccupee: surfaceOccupee,
          nombrePieds: nombrePieds,
        );
    await _recharger();
    return plantation;
  }

  Future<void> supprimer(String id) async {
    await ref.read(plantationRepositoryProvider).supprimer(id);
    await _recharger();
  }

  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(plantationRepositoryProvider)
          .obtenirParParcelle(parcelleId),
    );
  }
}

/// Plantations of a parcelle, keyed by `parcelleId`.
final plantationsProvider = AsyncNotifierProvider.family<PlantationsNotifier,
    List<Plantation>, String>(
  PlantationsNotifier.new,
);
