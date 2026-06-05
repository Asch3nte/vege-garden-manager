import 'package:drift/drift.dart';

import '../../domain/entities/observation.dart';
import '../../domain/enums/cible_observation.dart';
import '../../domain/enums/gravite_observation.dart';
import '../../domain/enums/type_observation.dart';
import '../database/app_database.dart';

/// Maps an [Observation] between the domain entity and its drift row.
///
/// The polymorphic target (`cible` + `cibleId`) is stored as exactly one of the
/// three nullable FK columns (`potager_id` / `parcelle_id` / `plantation_id`).
class ObservationMapper {
  const ObservationMapper();

  Observation versEntite(ObservationRow r) {
    final (cible, cibleId) = switch (r) {
      _ when r.potagerId != null => (CibleObservation.potager, r.potagerId!),
      _ when r.parcelleId != null => (CibleObservation.parcelle, r.parcelleId!),
      _ => (CibleObservation.plantation, r.plantationId!),
    };
    return Observation(
      id: r.id,
      cible: cible,
      cibleId: cibleId,
      date: DateTime.parse(r.dateObservation),
      type: TypeObservation.values.byName(r.type),
      titre: r.titre,
      gravite: GraviteObservation.values.byName(r.gravite),
      description: r.description,
      resolu: r.resolu,
      dateResolution: r.dateResolution == null
          ? null
          : DateTime.parse(r.dateResolution!),
      actionsRealisees: r.actionsRealisees,
      notes: r.notes,
    );
  }

  ObservationsCompanion versCompanion(Observation o) {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    return ObservationsCompanion(
      id: Value(o.id),
      dateObservation: Value(o.date.toUtc().toIso8601String()),
      type: Value(o.type.name),
      gravite: Value(o.gravite.name),
      titre: Value(o.titre),
      description: Value(o.description),
      potagerId:
          Value(o.cible == CibleObservation.potager ? o.cibleId : null),
      parcelleId:
          Value(o.cible == CibleObservation.parcelle ? o.cibleId : null),
      plantationId:
          Value(o.cible == CibleObservation.plantation ? o.cibleId : null),
      resolu: Value(o.resolu),
      dateResolution: Value(o.dateResolution?.toUtc().toIso8601String()),
      actionsRealisees: Value(o.actionsRealisees),
      dateCreation: Value(maintenant),
      notes: Value(o.notes),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }
}
