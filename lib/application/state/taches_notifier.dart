import 'package:riverpod/riverpod.dart';

import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_tache.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_tache.dart';

/// Family argument identifying the task target.
typedef CibleTacheScope = ({CibleTache cible, String cibleId});

/// Exposes the tasks of a given target and the actions that mutate them.
///
/// Family-scoped by a `(cible, cibleId)` record.
class TachesNotifier extends AsyncNotifier<List<Tache>> {
  TachesNotifier(this.scope);

  /// The task target (family argument).
  final CibleTacheScope scope;

  @override
  Future<List<Tache>> build() {
    return ref
        .watch(tacheRepositoryProvider)
        .obtenirParCible(scope.cible, scope.cibleId);
  }

  Future<Tache> creer({
    required String titre,
    required TypeTache type,
    required DateTime datePrevue,
    String? description,
    PrioriteTache priorite = PrioriteTache.normale,
    String? rappelOrigineId,
    String? notes,
  }) async {
    final tache = await ref.read(creerTacheProvider).executer(
          titre: titre,
          type: type,
          cible: scope.cible,
          cibleId: scope.cibleId,
          datePrevue: datePrevue,
          description: description,
          priorite: priorite,
          rappelOrigineId: rappelOrigineId,
          notes: notes,
        );
    await _recharger();
    return tache;
  }

  Future<void> supprimer(String id) async {
    await ref.read(tacheRepositoryProvider).supprimer(id);
    await _recharger();
  }

  /// Persists changes to an existing task (upsert) and reloads the list.
  /// The caller mutates the entity through its domain methods first
  /// (e.g. `marquerFaite`, `reporter`).
  Future<void> modifier(Tache tache) async {
    await ref.read(tacheRepositoryProvider).sauvegarder(tache);
    await _recharger();
  }

  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(tacheRepositoryProvider)
          .obtenirParCible(scope.cible, scope.cibleId),
    );
  }
}

/// Tasks of a target, keyed by `(cible, cibleId)`.
final tachesProvider = AsyncNotifierProvider.family<TachesNotifier,
    List<Tache>, CibleTacheScope>(
  TachesNotifier.new,
);
