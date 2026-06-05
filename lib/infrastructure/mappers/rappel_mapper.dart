import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/rappel.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/etat_rappel.dart';
import '../../domain/enums/jour_semaine.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_recurrence.dart';
import '../../domain/enums/type_tache.dart';
import '../database/app_database.dart';

/// Maps a [Rappel] between the domain entity and its drift row.
///
/// The polymorphic target ([CibleTache] + cibleId) is stored as exactly one of
/// the four nullable FK columns. The weekdays set is serialised as a JSON array
/// of enum `name`s in `jours_semaine`; an empty set is stored as `null` (which
/// the schema CHECK allows for non-weekly recurrences). Enums are persisted as
/// their camelCase `name`.
class RappelMapper {
  const RappelMapper();

  Rappel versEntite(RappelRow r) {
    final (cible, cibleId) = switch (r) {
      _ when r.potagerId != null => (CibleTache.potager, r.potagerId!),
      _ when r.parcelleId != null => (CibleTache.parcelle, r.parcelleId!),
      _ when r.plantationId != null => (CibleTache.plantation, r.plantationId!),
      _ => (CibleTache.equipement, r.equipementId!),
    };
    return Rappel(
      id: r.id,
      titre: r.titre,
      description: r.description,
      typeTacheGeneree: TypeTache.values.byName(r.typeTacheGeneree),
      priorite: PrioriteTache.values.byName(r.priorite),
      cible: cible,
      cibleId: cibleId,
      dateDebut: DateTime.parse(r.dateDebut),
      dateFin: r.dateFin == null ? null : DateTime.parse(r.dateFin!),
      typeRecurrence: TypeRecurrence.values.byName(r.typeRecurrence),
      intervalleJours: r.intervalleJours,
      joursSemaine: _decoderJours(r.joursSemaine),
      jourDuMois: r.jourDuMois,
      etat: EtatRappel.values.byName(r.etat),
      genererXJoursAvance: r.genererXJoursAvance,
      notes: r.notes,
    );
  }

  RappelsCompanion versCompanion(Rappel r) {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    return RappelsCompanion(
      id: Value(r.id),
      titre: Value(r.titre),
      description: Value(r.description),
      typeTacheGeneree: Value(r.typeTacheGeneree.name),
      priorite: Value(r.priorite.name),
      potagerId: Value(r.cible == CibleTache.potager ? r.cibleId : null),
      parcelleId: Value(r.cible == CibleTache.parcelle ? r.cibleId : null),
      plantationId: Value(r.cible == CibleTache.plantation ? r.cibleId : null),
      equipementId: Value(r.cible == CibleTache.equipement ? r.cibleId : null),
      dateDebut: Value(r.dateDebut.toUtc().toIso8601String()),
      dateFin: Value(r.dateFin?.toUtc().toIso8601String()),
      typeRecurrence: Value(r.typeRecurrence.name),
      intervalleJours: Value(r.intervalleJours),
      joursSemaine: Value(_encoderJours(r.joursSemaine)),
      jourDuMois: Value(r.jourDuMois),
      etat: Value(r.etat.name),
      genererXJoursAvance: Value(r.genererXJoursAvance),
      dateCreation: Value(maintenant),
      notes: Value(r.notes),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }

  /// `null` for an empty set, otherwise a JSON array of weekday `name`s.
  String? _encoderJours(Set<JourSemaine> jours) =>
      jours.isEmpty ? null : jsonEncode(jours.map((j) => j.name).toList());

  Set<JourSemaine> _decoderJours(String? json) {
    if (json == null) return const <JourSemaine>{};
    final names = (jsonDecode(json) as List).cast<String>();
    return names.map(JourSemaine.values.byName).toSet();
  }
}
