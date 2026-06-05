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
}
