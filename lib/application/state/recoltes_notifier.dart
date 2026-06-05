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
    await _recharger();
    return recolte;
  }

  /// Persists changes to an existing harvest (upsert) and reloads the list.
  /// The caller mutates the entity through its domain methods first
  /// (e.g. `definirQualite`).
  Future<void> modifier(Recolte recolte) async {
    await ref.read(recolteRepositoryProvider).sauvegarder(recolte);
    await _recharger();
  }

  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(recolteRepositoryProvider)
          .obtenirParPlantation(plantationId),
    );
  }
}

/// Harvests of a plantation, keyed by `plantationId`.
final recoltesProvider =
    AsyncNotifierProvider.family<RecoltesNotifier, List<Recolte>, String>(
  RecoltesNotifier.new,
);
