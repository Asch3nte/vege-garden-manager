import 'package:drift/drift.dart';

import '../../domain/entities/recolte.dart';
import '../../domain/repositories/abstract_recolte_repository.dart';
import '../database/app_database.dart';
import '../database/lecteur_lignes.dart';
import '../database/upsert_conservant_creation.dart';
import '../mappers/recolte_mapper.dart';

/// drift-backed implementation of [AbstractRecolteRepository].
class RecolteRepositoryImpl implements AbstractRecolteRepository {
  final AppDatabase _db;
  final RecolteMapper _mapper = const RecolteMapper();
  final LecteurLignes _lecteur;

  RecolteRepositoryImpl(this._db, {this._lecteur = const LecteurLignes()});

  @override
  Future<List<Recolte>> obtenirParPlantation(String plantationId) async {
    final rows = await (_db.select(_db.recoltes)
          ..where((t) =>
              t.plantationId.equals(plantationId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateRecolte)]))
        .get();
    return _lecteur.lire(_db.recoltes.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<void> sauvegarder(Recolte recolte) async {
    await _db
        .into(_db.recoltes)
        .upsertConservantCreation(_mapper.versCompanion(recolte));
  }
}
