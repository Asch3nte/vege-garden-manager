import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_tache.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../providers/repository_providers.dart';

/// Use case: create a task on a target (potager/parcelle/plantation/equipment).
///
/// Generates the UUID app-side (injectable for tests) and persists the entity.
class CreerTache {
  final AbstractTacheRepository _repo;
  final String Function() _genererId;

  CreerTache(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  Future<Tache> executer({
    required String titre,
    required TypeTache type,
    required CibleTache cible,
    required String cibleId,
    required DateTime datePrevue,
    String? description,
    PrioriteTache priorite = PrioriteTache.normale,
    String? rappelOrigineId,
    String? notes,
  }) async {
    final tache = Tache(
      id: _genererId(),
      titre: titre,
      type: type,
      cible: cible,
      cibleId: cibleId,
      datePrevue: datePrevue,
      description: description,
      priorite: priorite,
      rappelOrigineId: rappelOrigineId,
      notes: notes,
    );
    await _repo.sauvegarder(tache);
    return tache;
  }
}

/// DI provider for [CreerTache].
final creerTacheProvider = Provider<CreerTache>(
  (ref) => CreerTache(ref.watch(tacheRepositoryProvider)),
);
