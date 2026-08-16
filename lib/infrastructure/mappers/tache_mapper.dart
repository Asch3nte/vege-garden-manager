import 'package:drift/drift.dart';

import '../../core/utils/date_iso.dart';
import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/enums/etat_tache.dart';
import '../../domain/enums/priorite_tache.dart';
import '../../domain/enums/type_tache.dart';
import '../database/app_database.dart';

/// Maps a [Tache] between the domain entity and its drift row.
///
/// The polymorphic target ([CibleTache] + cibleId) is stored as exactly one of
/// the four nullable FK columns (`potager_id` / `parcelle_id` /
/// `plantation_id` / `equipement_id`). Enums are persisted as their camelCase
/// `name`.
class TacheMapper {
  const TacheMapper();

  Tache versEntite(TacheRow r) {
    final (cible, cibleId) = switch (r) {
      _ when r.potagerId != null => (CibleTache.potager, r.potagerId!),
      _ when r.parcelleId != null => (CibleTache.parcelle, r.parcelleId!),
      _ when r.plantationId != null => (CibleTache.plantation, r.plantationId!),
      _ => (CibleTache.equipement, r.equipementId!),
    };
    return Tache(
      id: r.id,
      titre: r.titre,
      description: r.description,
      type: TypeTache.values.byName(r.type),
      etat: EtatTache.values.byName(r.etat),
      priorite: PrioriteTache.values.byName(r.priorite),
      cible: cible,
      cibleId: cibleId,
      datePrevue: DateIso.depuisStockage(r.datePrevue),
      dateRealisation: DateIso.depuisStockageNullable(r.dateRealisation),
      dureeReelleMinutes: r.dureeReelleMinutes,
      rappelOrigineId: r.rappelOrigineId,
      notes: r.notes,
    );
  }

  TachesCompanion versCompanion(Tache t) {
    final maintenant = DateIso.maintenant();
    return TachesCompanion(
      id: Value(t.id),
      titre: Value(t.titre),
      description: Value(t.description),
      type: Value(t.type.name),
      etat: Value(t.etat.name),
      priorite: Value(t.priorite.name),
      potagerId: Value(t.cible == CibleTache.potager ? t.cibleId : null),
      parcelleId: Value(t.cible == CibleTache.parcelle ? t.cibleId : null),
      plantationId: Value(t.cible == CibleTache.plantation ? t.cibleId : null),
      equipementId: Value(t.cible == CibleTache.equipement ? t.cibleId : null),
      datePrevue: Value(DateIso.versStockage(t.datePrevue)),
      dateRealisation: Value(DateIso.versStockageNullable(t.dateRealisation)),
      dureeReelleMinutes: Value(t.dureeReelleMinutes),
      rappelOrigineId: Value(t.rappelOrigineId),
      dateCreation: Value(maintenant),
      notes: Value(t.notes),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }
}
