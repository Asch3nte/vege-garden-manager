import 'package:drift/drift.dart';

import '../../domain/entities/rappel.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/repositories/abstract_rappel_repository.dart';
import '../database/app_database.dart';
import '../mappers/rappel_mapper.dart';

/// drift-backed implementation of [AbstractRappelRepository].
class RappelRepositoryImpl implements AbstractRappelRepository {
  final AppDatabase _db;
  final RappelMapper _mapper = const RappelMapper();

  RappelRepositoryImpl(this._db);

  @override
  Future<List<Rappel>> obtenirActifs() async {
    final rows = await (_db.select(_db.rappels)
          ..where((t) => t.etat.equals('actif') & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateDebut)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<List<Rappel>> obtenirParCible(CibleTache cible, String cibleId) async {
    final rows = await (_db.select(_db.rappels)
          ..where((t) {
            final cibleMatch = switch (cible) {
              CibleTache.potager => t.potagerId.equals(cibleId),
              CibleTache.parcelle => t.parcelleId.equals(cibleId),
              CibleTache.plantation => t.plantationId.equals(cibleId),
              CibleTache.equipement => t.equipementId.equals(cibleId),
            };
            return cibleMatch & t.deletedAt.isNull();
          })
          ..orderBy([(t) => OrderingTerm.asc(t.dateDebut)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<Rappel?> obtenirParId(String id) async {
    final row = await (_db.select(_db.rappels)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<void> sauvegarder(Rappel rappel) async {
    await _db
        .into(_db.rappels)
        .insertOnConflictUpdate(_mapper.versCompanion(rappel));
  }

  @override
  Future<void> supprimer(String id) async {
    await (_db.update(_db.rappels)..where((t) => t.id.equals(id))).write(
      RappelsCompanion(
        deletedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }
}
