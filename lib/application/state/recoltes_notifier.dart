import 'package:riverpod/riverpod.dart';

import '../../domain/entities/recolte.dart';
import '../../domain/enums/destination_recolte.dart';
import '../../domain/enums/qualite_recolte.dart';
import '../../domain/value_objects/quantite.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_recolte.dart';

/// Exposes the harvests of a given plantation and the action to add one.
///
/// Family-scoped by `plantationId`. Harvests are never deleted (the repository
/// has no delete), so this notifier only creates.
class RecoltesNotifier extends AsyncNotifier<List<Recolte>> {
  RecoltesNotifier(this.plantationId);

  /// The plantation whose harvests this notifier exposes (family argument).
  final String plantationId;

  @override
  Future<List<Recolte>> build() {
    return ref
        .watch(recolteRepositoryProvider)
        .obtenirParPlantation(plantationId);
  }

  Future<Recolte> creer({
    required DateTime date,
    required Quantite quantite,
    DestinationRecolte destination = DestinationRecolte.consommationFraiche,
    QualiteRecolte? qualite,
    String? notes,
  }) async {
    final recolte = await ref.read(creerRecolteProvider).executer(
          plantationId: plantationId,
          date: date,
          quantite: quantite,
          destination: destination,
          qualite: qualite,
          notes: notes,
        );
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(recolteRepositoryProvider)
          .obtenirParPlantation(plantationId),
    );
    return recolte;
  }
}

/// Harvests of a plantation, keyed by `plantationId`.
final recoltesProvider =
    AsyncNotifierProvider.family<RecoltesNotifier, List<Recolte>, String>(
  RecoltesNotifier.new,
);
