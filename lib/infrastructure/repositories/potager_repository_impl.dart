import 'package:drift/drift.dart';

import '../../domain/entities/potager.dart';
import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/repositories/abstract_potager_repository.dart';
import '../database/app_database.dart';
import '../mappers/potager_mapper.dart';
import 'suppression_cascade.dart';

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

  // ADR-0009 (multi-potager): the active garden is the user's persisted
  // selection (preferences.potagerActifId), when it still resolves to a
  // non-deleted garden. Otherwise (no selection yet, or it points at a
  // deleted/missing garden) it falls back to the earliest-created one.
  @override
  Future<Potager?> obtenirPotagerActif() async {
    final prefs = await (_db.select(_db.preferences)
          ..where((t) => t.id.equals(PreferencesUtilisateur.idSingleton)))
        .getSingleOrNull();
    final choixId = prefs?.potagerActifId;
    if (choixId != null) {
      final choisi = await (_db.select(_db.potagers)
            ..where((t) => t.id.equals(choixId) & t.deletedAt.isNull()))
          .getSingleOrNull();
      if (choisi != null) return _mapper.versEntite(choisi);
    }
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
      // Gather the dependent hierarchy ids first, so the order of the
      // soft-delete statements below is irrelevant to correctness.
      final parcelleIds = await (_db.selectOnly(_db.parcelles)
            ..addColumns([_db.parcelles.id])
            ..where(_db.parcelles.potagerId.equals(id)))
          .map((r) => r.read(_db.parcelles.id)!)
          .get();

      final plantationIds = parcelleIds.isEmpty
          ? const <String>[]
          : await (_db.selectOnly(_db.plantations)
                ..addColumns([_db.plantations.id])
                ..where(_db.plantations.parcelleId.isIn(parcelleIds)))
              .map((r) => r.read(_db.plantations.id)!)
              .get();

      // Equipements belong to the potager (parcelle is optional), so scope by
      // potagerId — this also catches potager-level equipements (parcelle null).
      final equipementIds = await (_db.selectOnly(_db.equipements)
            ..addColumns([_db.equipements.id])
            ..where(_db.equipements.potagerId.equals(id)))
          .map((r) => r.read(_db.equipements.id)!)
          .get();

      // Tasks/reminders/observations pointing at this potager or any element of
      // its hierarchy, so deleting a potager never orphans them.
      await soustraireLignesDePlanification(_db, maintenant,
          potagerId: id,
          parcelleIds: parcelleIds,
          plantationIds: plantationIds,
          equipementIds: equipementIds);

      if (plantationIds.isNotEmpty) {
        await (_db.update(_db.recoltes)
              ..where((t) =>
                  t.plantationId.isIn(plantationIds) & t.deletedAt.isNull()))
            .write(RecoltesCompanion(deletedAt: Value(maintenant)));
        await (_db.update(_db.plantations)
              ..where((t) =>
                  t.parcelleId.isIn(parcelleIds) & t.deletedAt.isNull()))
            .write(PlantationsCompanion(deletedAt: Value(maintenant)));
      }
      await (_db.update(_db.equipements)
            ..where((t) => t.potagerId.equals(id) & t.deletedAt.isNull()))
          .write(EquipementsCompanion(deletedAt: Value(maintenant)));
      await (_db.update(_db.parcelles)
            ..where((t) => t.potagerId.equals(id) & t.deletedAt.isNull()))
          .write(ParcellesCompanion(deletedAt: Value(maintenant)));
      await (_db.update(_db.potagers)..where((t) => t.id.equals(id)))
          .write(PotagersCompanion(deletedAt: Value(maintenant)));
    });
  }
}
