import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/rappel.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/jour_semaine.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_recurrence.dart';
import '../../domain/enums/type_tache.dart';
import '../../domain/repositories/abstract_rappel_repository.dart';
import '../providers/repository_providers.dart';

/// Use case: create a reminder (the rule that generates tasks).
///
/// Generates the UUID app-side (injectable for tests) and persists the entity.
/// Recurrence parameters are validated by the entity according to
/// [typeRecurrence].
class CreerRappel {
  final AbstractRappelRepository _repo;
  final String Function() _genererId;

  CreerRappel(this._repo, {String Function()? genererId})
      : _genererId = genererId ?? _uuid;

  static String _uuid() => const Uuid().v4();

  Future<Rappel> executer({
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
    final rappel = Rappel(
      id: _genererId(),
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
    await _repo.sauvegarder(rappel);
    return rappel;
  }
}

/// DI provider for [CreerRappel].
final creerRappelProvider = Provider<CreerRappel>(
  (ref) => CreerRappel(ref.watch(rappelRepositoryProvider)),
);
