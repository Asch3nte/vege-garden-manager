import 'package:drift/drift.dart';

import '../../domain/entities/fiche_plante_personnelle.dart';
import '../../domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import '../database/app_database.dart';
import '../mappers/fiche_plante_personnelle_mapper.dart';

/// drift-backed implementation of [AbstractFichePlantePersonnelleRepository].
class FichePlantePersonnelleRepositoryImpl
    implements AbstractFichePlantePersonnelleRepository {
  final AppDatabase _db;
  final FichePlantePersonnelleMapper _mapper =
      const FichePlantePersonnelleMapper();

  FichePlantePersonnelleRepositoryImpl(this._db);

  @override
  Future<List<FichePlantePersonnelle>> obtenirToutes() async {
    final rows = await (_db.select(_db.fichesPlantesPersonnelles)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<FichePlantePersonnelle?> obtenirParId(String id) async {
    final row = await (_db.select(_db.fichesPlantesPersonnelles)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<FichePlantePersonnelle?> obtenirParIdFiche(String idFiche) async {
    final row = await (_db.select(_db.fichesPlantesPersonnelles)
          ..where((t) => t.idFiche.equals(idFiche) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapper.versEntite(row);
  }

  @override
  Future<List<String>> obtenirYamlBruts() async {
    final rows = await (_db.select(_db.fichesPlantesPersonnelles)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows.map((r) => r.yamlContenu).toList();
  }

  @override
  Future<void> sauvegarder(FichePlantePersonnelle fiche) async {
    await _db
        .into(_db.fichesPlantesPersonnelles)
        .insertOnConflictUpdate(_mapper.versCompanion(fiche));
  }

  @override
  Future<void> supprimer(String id) async {
    await (_db.update(_db.fichesPlantesPersonnelles)
          ..where((t) => t.id.equals(id)))
        .write(
      FichesPlantesPersonnellesCompanion(
        deletedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }
}
