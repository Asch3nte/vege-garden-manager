import 'package:drift/drift.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/enums/statut_plantation.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../database/app_database.dart';
import '../mappers/plantation_mapper.dart';
import 'suppression_cascade.dart';

/// drift-backed implementation of [AbstractPlantationRepository].
///
/// Reads filter out soft-deleted rows. [supprimer] soft-deletes the plantation
/// and, by logical cascade, its harvests and the planning rows (tasks,
/// reminders, observations) that target it.
class PlantationRepositoryImpl implements AbstractPlantationRepository {
  final AppDatabase _db;
  final PlantationMapper _mapper = const PlantationMapper();

  PlantationRepositoryImpl(this._db);

  @override
  Future<Plantation?> obtenirParId(String id) async {
    final row = await (_db.select(_db.plantations)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<List<Plantation>> obtenirParParcelle(String parcelleId) async {
    final rows = await (_db.select(_db.plantations)
          ..where((t) => t.parcelleId.equals(parcelleId) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<List<Plantation>> obtenirActives() async {
    final rows = await (_db.select(_db.plantations)
          ..where((t) =>
              t.statut.equals(StatutPlantation.enCours.name) &
              t.deletedAt.isNull()))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<void> sauvegarder(Plantation plantation) async {
    await _db
        .into(_db.plantations)
        .insertOnConflictUpdate(_mapper.versCompanion(plantation));
  }

  @override
  Future<void> supprimer(String id) async {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    await _db.transaction(() async {
      // Tasks/reminders/observations targeting this plantation — so deleting a
      // crop never orphans them.
      await soustraireLignesDePlanification(_db, maintenant,
          plantationIds: [id]);
      await (_db.update(_db.recoltes)
            ..where((t) => t.plantationId.equals(id) & t.deletedAt.isNull()))
          .write(RecoltesCompanion(deletedAt: Value(maintenant)));
      await (_db.update(_db.plantations)..where((t) => t.id.equals(id)))
          .write(PlantationsCompanion(deletedAt: Value(maintenant)));
    });
  }
}
