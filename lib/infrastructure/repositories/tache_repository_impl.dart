import 'package:drift/drift.dart';

import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../database/app_database.dart';
import '../mappers/tache_mapper.dart';

/// drift-backed implementation of [AbstractTacheRepository].
class TacheRepositoryImpl implements AbstractTacheRepository {
  final AppDatabase _db;
  final TacheMapper _mapper = const TacheMapper();

  TacheRepositoryImpl(this._db);

  @override
  Future<List<Tache>> obtenirParCible(CibleTache cible, String cibleId) async {
    final rows = await (_db.select(_db.taches)
          ..where((t) {
            final cibleMatch = switch (cible) {
              CibleTache.potager => t.potagerId.equals(cibleId),
              CibleTache.parcelle => t.parcelleId.equals(cibleId),
              CibleTache.plantation => t.plantationId.equals(cibleId),
              CibleTache.equipement => t.equipementId.equals(cibleId),
            };
            return cibleMatch & t.deletedAt.isNull();
          })
          ..orderBy([(t) => OrderingTerm.asc(t.datePrevue)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<Tache?> obtenirParId(String id) async {
    final row = await (_db.select(_db.taches)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<List<Tache>> obtenirEntreDates(DateTime debut, DateTime fin) async {
    final debutIso = debut.toUtc().toIso8601String();
    final finIso = fin.toUtc().toIso8601String();
    final rows = await (_db.select(_db.taches)
          ..where((t) =>
              t.datePrevue.isBiggerOrEqualValue(debutIso) &
              t.datePrevue.isSmallerOrEqualValue(finIso) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.datePrevue)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<List<Tache>> obtenirParRappel(String rappelOrigineId) async {
    final rows = await (_db.select(_db.taches)
          ..where((t) =>
              t.rappelOrigineId.equals(rappelOrigineId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.datePrevue)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<void> sauvegarder(Tache tache) async {
    await _db
        .into(_db.taches)
        .insertOnConflictUpdate(_mapper.versCompanion(tache));
  }

  @override
  Future<void> supprimer(String id) async {
    await (_db.update(_db.taches)..where((t) => t.id.equals(id))).write(
      TachesCompanion(
        deletedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }
}
