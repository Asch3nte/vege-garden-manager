import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Soft-deletes every planning row — task, reminder, observation — whose single
/// target points at one of the given hierarchy ids.
///
/// Tasks, reminders and observations each reference **exactly one** target
/// among potager / parcelle / plantation / equipement (table CHECK constraint),
/// so the per-table predicate simply OR-combines the relevant columns. The
/// absent [potagerId] and empty id lists are skipped, and a table with no
/// applicable target is left untouched (observations carry no equipement
/// target, so [equipementIds] never applies to them).
///
/// Shared by the potager / parcelle / plantation repositories so that deleting
/// any node of the hierarchy never orphans the rows that reference it. Must be
/// called inside the deletion transaction.
Future<void> soustraireLignesDePlanification(
  AppDatabase db,
  String maintenant, {
  String? potagerId,
  List<String> parcelleIds = const [],
  List<String> plantationIds = const [],
  List<String> equipementIds = const [],
}) async {
  Expression<bool>? predicat(
    Expression<String> potagerCol,
    Expression<String> parcelleCol,
    Expression<String> plantationCol,
    Expression<String>? equipementCol,
  ) {
    Expression<bool>? combine;
    void ajouter(Expression<bool> condition) =>
        combine = combine == null ? condition : combine! | condition;

    if (potagerId != null) ajouter(potagerCol.equals(potagerId));
    if (parcelleIds.isNotEmpty) ajouter(parcelleCol.isIn(parcelleIds));
    if (plantationIds.isNotEmpty) ajouter(plantationCol.isIn(plantationIds));
    if (equipementCol != null && equipementIds.isNotEmpty) {
      ajouter(equipementCol.isIn(equipementIds));
    }
    return combine;
  }

  final pTaches = predicat(db.taches.potagerId, db.taches.parcelleId,
      db.taches.plantationId, db.taches.equipementId);
  if (pTaches != null) {
    await (db.update(db.taches)
          ..where((_) => pTaches & db.taches.deletedAt.isNull()))
        .write(TachesCompanion(deletedAt: Value(maintenant)));
  }

  final pRappels = predicat(db.rappels.potagerId, db.rappels.parcelleId,
      db.rappels.plantationId, db.rappels.equipementId);
  if (pRappels != null) {
    await (db.update(db.rappels)
          ..where((_) => pRappels & db.rappels.deletedAt.isNull()))
        .write(RappelsCompanion(deletedAt: Value(maintenant)));
  }

  final pObservations = predicat(db.observations.potagerId,
      db.observations.parcelleId, db.observations.plantationId, null);
  if (pObservations != null) {
    await (db.update(db.observations)
          ..where((_) => pObservations & db.observations.deletedAt.isNull()))
        .write(ObservationsCompanion(deletedAt: Value(maintenant)));
  }
}
