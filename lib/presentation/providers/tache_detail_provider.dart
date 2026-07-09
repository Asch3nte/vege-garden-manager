import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/repository_providers.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';

/// A task plus the resolved display name of its target (zone / crop / garden).
class TacheDetailVue {
  final Tache _tache;
  final String? _cibleNom;

  const TacheDetailVue(this._tache, this._cibleNom);

  /// The task itself.
  Tache get tache => _tache;

  /// Resolved target name, or `null` when it can't be resolved (deleted target,
  /// equipment with no screen, a non-active garden).
  String? get cibleNom => _cibleNom;
}

/// Loads a task by id for the detail screen, resolving its target's name the
/// same way the calendar does. Returns `null` when the task no longer exists
/// (e.g. deleted from another surface). Auto-disposed and family-keyed by id.
final tacheDetailProvider =
    FutureProvider.autoDispose.family<TacheDetailVue?, String>((ref, id) async {
  final tache = await ref.watch(tacheRepositoryProvider).obtenirParId(id);
  if (tache == null) return null;
  return TacheDetailVue(tache, await _resoudreNom(ref, tache));
});

/// Display name of a task's target, mirroring `CalendrierNotifier._nomCible`.
Future<String?> _resoudreNom(Ref ref, Tache tache) async {
  switch (tache.cible) {
    case CibleTache.potager:
      final actif =
          await ref.watch(potagerRepositoryProvider).obtenirPotagerActif();
      return actif?.id == tache.cibleId ? actif!.nom : null;
    case CibleTache.parcelle:
      return (await ref.watch(parcelleRepositoryProvider).obtenirParId(
            tache.cibleId,
          ))
          ?.nom;
    case CibleTache.plantation:
      final plantation = await ref
          .watch(plantationRepositoryProvider)
          .obtenirParId(tache.cibleId);
      if (plantation == null) return null;
      final fiches = await ref.watch(fichePlanteRepositoryProvider.future);
      return (await fiches.obtenirParId(plantation.planteId))
          ?.nomLocalise('fr');
    case CibleTache.equipement:
      return null;
  }
}
