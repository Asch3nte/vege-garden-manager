import 'package:riverpod/riverpod.dart';

import '../../domain/entities/rappel.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/jour_semaine.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_recurrence.dart';
import '../../domain/enums/type_tache.dart';
import '../providers/repository_providers.dart';
import '../use_cases/creer_rappel.dart';

/// Exposes the active reminders and the actions that mutate them.
///
/// Not family-scoped: the primary list is the active reminders across the whole
/// app (the set the task-generation engine iterates over).
class RappelsActifsNotifier extends AsyncNotifier<List<Rappel>> {
  @override
  Future<List<Rappel>> build() {
    return ref.watch(rappelRepositoryProvider).obtenirActifs();
  }

  Future<Rappel> creer({
    required String titre,
    required TypeTache typeTacheGeneree,
    required CibleTache cible,
    required String cibleId,
    required DateTime dateDebut,
    required TypeRecurrence typeRecurrence,
    String? description,
    PrioriteTache priorite = PrioriteTache.normale,
    DateTime? dateFin,
    int? intervalleJours,
    Set<JourSemaine>? joursSemaine,
    int? jourDuMois,
    int genererXJoursAvance = 7,
    String? notes,
  }) async {
    final rappel = await ref.read(creerRappelProvider).executer(
          titre: titre,
          typeTacheGeneree: typeTacheGeneree,
          cible: cible,
          cibleId: cibleId,
          dateDebut: dateDebut,
          typeRecurrence: typeRecurrence,
          description: description,
          priorite: priorite,
          dateFin: dateFin,
          intervalleJours: intervalleJours,
          joursSemaine: joursSemaine,
          jourDuMois: jourDuMois,
          genererXJoursAvance: genererXJoursAvance,
          notes: notes,
        );
    await _recharger();
    return rappel;
  }

  Future<void> supprimer(String id) async {
    await ref.read(rappelRepositoryProvider).supprimer(id);
    await _recharger();
  }

  Future<void> _recharger() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(rappelRepositoryProvider).obtenirActifs(),
    );
  }
}

/// The active reminders.
final rappelsActifsProvider =
    AsyncNotifierProvider<RappelsActifsNotifier, List<Rappel>>(
  RappelsActifsNotifier.new,
);
