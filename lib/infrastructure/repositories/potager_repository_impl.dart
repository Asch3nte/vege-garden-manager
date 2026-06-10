import 'package:drift/drift.dart';

import '../../domain/entities/potager.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../database/app_database.dart';
import '../mappers/potager_mapper.dart';

/// drift-backed implementation of [AbstractPotagerRepository].
///
/// Reads filter out soft-deleted rows (`deleted_at IS NULL`). Hydration is
/// shallow (no nested parcelles).
class PotagerRepositoryImpl implements AbstractPotagerRepository {
  final AppDatabase _db;
  final PotagerMapper _mapper = const PotagerMapper();

  PotagerRepositoryImpl(this._db);

  @override
  Future<List<Potager>> obtenirTous() async {
    final rows = await (_db.select(_db.potagers)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateCreation)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  // TODO(active): the "active" potager is, for now, the earliest non-deleted
  // one. A persisted user selection (parametres) will refine this later.
  @override
  Future<Potager?> obtenirPotagerActif() async {
    final row = await (_db.select(_db.potagers)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateCreation)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<void> sauvegarder(Potager potager) async {
    await _db
        .into(_db.potagers)
        .insertOnConflictUpdate(_mapper.versCompanion(potager));
  }

  @override
  Future<void> supprimer(String id) async {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    await _db.transaction(() async {
      final parcelleIds = await (_db.selectOnly(_db.parcelles)
            ..addColumns([_db.parcelles.id])
            ..where(_db.parcelles.potagerId.equals(id)))
          .map((r) => r.read(_db.parcelles.id)!)
          .get();

      if (parcelleIds.isNotEmpty) {
        final plantationIds = await (_db.selectOnly(_db.plantations)
              ..addColumns([_db.plantations.id])
              ..where(_db.plantations.parcelleId.isIn(parcelleIds)))
            .map((r) => r.read(_db.plantations.id)!)
            .get();
        if (plantationIds.isNotEmpty) {
          await (_db.update(_db.recoltes)
                ..where((t) =>
                    t.plantationId.isIn(plantationIds) & t.deletedAt.isNull()))
              .write(RecoltesCompanion(deletedAt: Value(maintenant)));
        }
        await (_db.update(_db.plantations)
              ..where((t) =>
                  t.parcelleId.isIn(parcelleIds) & t.deletedAt.isNull()))
            .write(PlantationsCompanion(deletedAt: Value(maintenant)));
        await (_db.update(_db.equipements)
              ..where((t) =>
                  t.parcelleId.isIn(parcelleIds) & t.deletedAt.isNull()))
            .write(EquipementsCompanion(deletedAt: Value(maintenant)));
      }
      await (_db.update(_db.parcelles)
            ..where((t) => t.potagerId.equals(id) & t.deletedAt.isNull()))
          .write(ParcellesCompanion(deletedAt: Value(maintenant)));
      await (_db.update(_db.potagers)..where((t) => t.id.equals(id)))
          .write(PotagersCompanion(deletedAt: Value(maintenant)));
    });
  }
}
