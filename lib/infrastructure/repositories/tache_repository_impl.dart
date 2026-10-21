import 'package:drift/drift.dart';

import '../../domain/entities/tache.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/repositories/abstract_tache_repository.dart';
import '../database/app_database.dart';
import '../database/lecteur_lignes.dart';
import '../database/upsert_conservant_creation.dart';
import '../mappers/tache_mapper.dart';

/// drift-backed implementation of [AbstractTacheRepository].
class TacheRepositoryImpl implements AbstractTacheRepository {
  final AppDatabase _db;
  final TacheMapper _mapper = const TacheMapper();
  final LecteurLignes _lecteur;

  TacheRepositoryImpl(this._db, {this._lecteur = const LecteurLignes()});

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
    return _lecteur.lire(_db.taches.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<Tache?> obtenirParId(String id) async {
    final row = await (_db.select(_db.taches)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return _lecteur.lireUne(_db.taches.actualTableName, row,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<List<Tache>> obtenirEntreDates(DateTime debut, DateTime fin) async {
    final debutIso = debut.toUtc().toIso8601String();
    final finIso = fin.toUtc().toIso8601String();
    final rows = await (_db.select(_db.taches)
          ..where((t) =>
              t.datePrevue.isBiggerOrEqualValue(debutIso) &
              t.datePrevue.isSmallerThanValue(finIso) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.datePrevue)]))
        .get();
    return _lecteur.lire(_db.taches.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<List<Tache>> obtenirParRappel(String rappelOrigineId) async {
    final rows = await (_db.select(_db.taches)
          ..where((t) =>
              t.rappelOrigineId.equals(rappelOrigineId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.datePrevue)]))
        .get();
    return _lecteur.lire(_db.taches.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<void> sauvegarder(Tache tache) async {
    await _db
        .into(_db.taches)
        .upsertConservantCreation(_mapper.versCompanion(tache));
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
