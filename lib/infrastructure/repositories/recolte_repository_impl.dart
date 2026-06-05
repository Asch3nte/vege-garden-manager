import 'package:drift/drift.dart';

import '../../domain/entities/recolte.dart';
import '../../domain/repositories/abstract_recolte_repository.dart';
import '../database/app_database.dart';
import '../mappers/recolte_mapper.dart';

/// drift-backed implementation of [AbstractRecolteRepository].
class RecolteRepositoryImpl implements AbstractRecolteRepository {
  final AppDatabase _db;
  final RecolteMapper _mapper = const RecolteMapper();

  RecolteRepositoryImpl(this._db);

  @override
  Future<List<Recolte>> obtenirParPlantation(String plantationId) async {
    final rows = await (_db.select(_db.recoltes)
          ..where((t) =>
              t.plantationId.equals(plantationId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateRecolte)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<void> sauvegarder(Recolte recolte) async {
    await _db
        .into(_db.recoltes)
        .insertOnConflictUpdate(_mapper.versCompanion(recolte));
  }
}
