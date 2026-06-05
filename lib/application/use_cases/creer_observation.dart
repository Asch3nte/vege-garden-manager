import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/observation.dart';
import '../../domain/enums/cible_observation.dart';
import '../../domain/enums/gravite_observation.dart';
import '../../domain/enums/type_observation.dart';
import '../../domain/repositories/abstract_observation_repository.dart';
import '../providers/repository_providers.dart';

/// Use case: log a journal observation on a target (potager/parcelle/plantation).
///
/// Generates the UUID app-side (injectable for tests) and persists the entity.
class CreerObservation {
  final AbstractObservationRepository _repo;
  final String Function() _genererId;

  CreerObservation(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  Future<Observation> executer({
    required CibleObservation cible,
    required String cibleId,
    required DateTime date,
    required TypeObservation type,
    required String titre,
    GraviteObservation gravite = GraviteObservation.info,
    String? description,
    String? notes,
  }) async {
    final observation = Observation(
      id: _genererId(),
      cible: cible,
      cibleId: cibleId,
      date: date,
      type: type,
      titre: titre,
      gravite: gravite,
      description: description,
      notes: notes,
    );
    await _repo.sauvegarder(observation);
    return observation;
  }
}

/// DI provider for [CreerObservation].
final creerObservationProvider = Provider<CreerObservation>(
  (ref) => CreerObservation(ref.watch(observationRepositoryProvider)),
);
