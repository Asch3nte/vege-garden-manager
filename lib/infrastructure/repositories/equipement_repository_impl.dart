import 'package:drift/drift.dart';

import '../../domain/entities/equipement.dart';
import '../../domain/repositories/abstract_equipement_repository.dart';
import '../database/app_database.dart';
import '../mappers/equipement_mapper.dart';

/// drift-backed implementation of [AbstractEquipementRepository].
class EquipementRepositoryImpl implements AbstractEquipementRepository {
  final AppDatabase _db;
  final EquipementMapper _mapper = const EquipementMapper();

  EquipementRepositoryImpl(this._db);

  @override
  Future<List<Equipement>> obtenirParPotager(String potagerId) async {
    final rows = await (_db.select(_db.equipements)
          ..where((t) => t.potagerId.equals(potagerId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateInstallation)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<List<Equipement>> obtenirParParcelle(String parcelleId) async {
    final rows = await (_db.select(_db.equipements)
          ..where((t) => t.parcelleId.equals(parcelleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateInstallation)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<Equipement?> obtenirParId(String id) async {
    final row = await (_db.select(_db.equipements)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<void> sauvegarder(Equipement equipement) async {
    await _db
        .into(_db.equipements)
        .insertOnConflictUpdate(_mapper.versCompanion(equipement));
  }

  @override
  Future<void> supprimer(String id) async {
    await (_db.update(_db.equipements)..where((t) => t.id.equals(id))).write(
      EquipementsCompanion(
        deletedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }
}
