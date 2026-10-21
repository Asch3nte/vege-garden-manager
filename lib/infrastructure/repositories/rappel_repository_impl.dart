import 'package:drift/drift.dart';

import '../../domain/entities/rappel.dart';
import '../../domain/enums/cible_tache.dart';
import '../../domain/repositories/abstract_rappel_repository.dart';
import '../database/app_database.dart';
import '../database/lecteur_lignes.dart';
import '../database/upsert_conservant_creation.dart';
import '../mappers/rappel_mapper.dart';

/// drift-backed implementation of [AbstractRappelRepository].
class RappelRepositoryImpl implements AbstractRappelRepository {
  final AppDatabase _db;
  final RappelMapper _mapper = const RappelMapper();
  final LecteurLignes _lecteur;

  RappelRepositoryImpl(this._db, {this._lecteur = const LecteurLignes()});

  @override
  Future<List<Rappel>> obtenirActifs() async {
    final rows = await (_db.select(_db.rappels)
          ..where((t) => t.etat.equals('actif') & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.dateDebut)]))
        .get();
    return _lecteur.lire(_db.rappels.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
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
    return _lecteur.lire(_db.rappels.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<Rappel?> obtenirParId(String id) async {
    final row = await (_db.select(_db.rappels)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return _lecteur.lireUne(_db.rappels.actualTableName, row,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<void> sauvegarder(Rappel rappel) async {
    await _db
        .into(_db.rappels)
        .upsertConservantCreation(_mapper.versCompanion(rappel));
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
