import 'package:riverpod/riverpod.dart';

import '../../domain/entities/observation.dart';
import '../../domain/enums/cible_observation.dart';
import '../../domain/enums/gravite_observation.dart';
import '../../domain/enums/type_observation.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_observation.dart';

/// Family argument identifying the observation target.
typedef CibleObservationScope = ({CibleObservation cible, String cibleId});

/// Exposes the observations of a given target and the actions that mutate them.
///
/// Family-scoped by a `(cible, cibleId)` record.
class ObservationsNotifier extends AsyncNotifier<List<Observation>> {
  ObservationsNotifier(this.scope);

  /// The observation target (family argument).
  final CibleObservationScope scope;

  @override
  Future<List<Observation>> build() {
    return ref
        .watch(observationRepositoryProvider)
        .obtenirParCible(scope.cible, scope.cibleId);
  }

  Future<Observation> creer({
    required DateTime date,
    required TypeObservation type,
    required String titre,
    GraviteObservation gravite = GraviteObservation.info,
    String? description,
    String? notes,
  }) async {
    final observation = await ref.read(creerObservationProvider).executer(
          cible: scope.cible,
          cibleId: scope.cibleId,
          date: date,
          type: type,
          titre: titre,
          gravite: gravite,
          description: description,
          notes: notes,
        );
    await _recharger();
    return observation;
  }

  Future<void> supprimer(String id) async {
    await ref.read(observationRepositoryProvider).supprimer(id);
    await _recharger();
  }

  /// Persists changes to an existing observation (upsert) and reloads the list.
  /// The caller mutates the entity through its domain methods first
  /// (e.g. `resoudre`).
  Future<void> modifier(Observation observation) async {
    await ref.read(observationRepositoryProvider).sauvegarder(observation);
    await _recharger();
  }

  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(observationRepositoryProvider)
          .obtenirParCible(scope.cible, scope.cibleId),
    );
  }
}

/// Observations of a target, keyed by `(cible, cibleId)`.
final observationsProvider = AsyncNotifierProvider.family<ObservationsNotifier,
    List<Observation>, CibleObservationScope>(
  ObservationsNotifier.new,
);
