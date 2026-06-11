import 'package:drift/drift.dart';

import '../../domain/entities/parcelle.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../database/app_database.dart';
import '../mappers/parcelle_mapper.dart';
import 'suppression_cascade.dart';

/// drift-backed implementation of [AbstractParcelleRepository].
///
/// Reads filter out soft-deleted rows. [supprimer] is a **soft delete** with a
/// **logical cascade**: the parcelle's plantations (and their harvests), its
/// equipments and the planning rows (tasks, reminders, observations) targeting
/// the parcelle or any of those are soft-deleted in the same transaction.
class ParcelleRepositoryImpl implements AbstractParcelleRepository {
  final AppDatabase _db;
  final ParcelleMapper _mapper = const ParcelleMapper();

  ParcelleRepositoryImpl(this._db);

  @override
  Future<List<Parcelle>> obtenirParPotager(String potagerId) async {
    final rows = await (_db.select(_db.parcelles)
          ..where((t) => t.potagerId.equals(potagerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.positionOrdre)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<Parcelle?> obtenirParId(String id) async {
    final row = await (_db.select(_db.parcelles)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<void> sauvegarder(Parcelle parcelle) async {
    await _db
        .into(_db.parcelles)
        .insertOnConflictUpdate(_mapper.versCompanion(parcelle));
  }

  @override
  Future<void> supprimer(String id) async {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    await _db.transaction(() async {
      final plantationIds = await (_db.selectOnly(_db.plantations)
            ..addColumns([_db.plantations.id])
            ..where(_db.plantations.parcelleId.equals(id)))
          .map((r) => r.read(_db.plantations.id)!)
          .get();
      final equipementIds = await (_db.selectOnly(_db.equipements)
            ..addColumns([_db.equipements.id])
            ..where(_db.equipements.parcelleId.equals(id)))
          .map((r) => r.read(_db.equipements.id)!)
          .get();

      // Tasks/reminders/observations targeting this parcelle, its plantations or
      // its equipements — so deleting a zone never orphans them.
      await soustraireLignesDePlanification(_db, maintenant,
          parcelleIds: [id],
          plantationIds: plantationIds,
          equipementIds: equipementIds);

      if (plantationIds.isNotEmpty) {
        await (_db.update(_db.recoltes)
              ..where((t) =>
                  t.plantationId.isIn(plantationIds) & t.deletedAt.isNull()))
            .write(RecoltesCompanion(deletedAt: Value(maintenant)));
      }
      await (_db.update(_db.plantations)
            ..where((t) => t.parcelleId.equals(id) & t.deletedAt.isNull()))
          .write(PlantationsCompanion(deletedAt: Value(maintenant)));
      await (_db.update(_db.equipements)
            ..where((t) => t.parcelleId.equals(id) & t.deletedAt.isNull()))
          .write(EquipementsCompanion(deletedAt: Value(maintenant)));
      await (_db.update(_db.parcelles)..where((t) => t.id.equals(id)))
          .write(ParcellesCompanion(deletedAt: Value(maintenant)));
    });
  }
}
