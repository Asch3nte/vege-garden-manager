import 'package:drift/drift.dart';

import '../../domain/entities/observation.dart';
import '../../domain/enums/cible_observation.dart';
import '../../domain/repositories/abstract_observation_repository.dart';
import '../database/app_database.dart';
import '../database/lecteur_lignes.dart';
import '../database/upsert_conservant_creation.dart';
import '../mappers/observation_mapper.dart';

/// drift-backed implementation of [AbstractObservationRepository].
class ObservationRepositoryImpl implements AbstractObservationRepository {
  final AppDatabase _db;
  final ObservationMapper _mapper = const ObservationMapper();
  final LecteurLignes _lecteur;

  ObservationRepositoryImpl(this._db, {this._lecteur = const LecteurLignes()});

  @override
  Future<List<Observation>> obtenirParCible(
    CibleObservation cible,
    String cibleId,
  ) async {
    final rows = await (_db.select(_db.observations)
          ..where((t) {
            final cibleMatch = switch (cible) {
              CibleObservation.potager => t.potagerId.equals(cibleId),
              CibleObservation.parcelle => t.parcelleId.equals(cibleId),
              CibleObservation.plantation => t.plantationId.equals(cibleId),
            };
            return cibleMatch & t.deletedAt.isNull();
          })
          ..orderBy([(t) => OrderingTerm.desc(t.dateObservation)]))
        .get();
    return _lecteur.lire(_db.observations.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<List<Observation>> obtenirNonResolues() async {
    final rows = await (_db.select(_db.observations)
          ..where((t) => t.resolu.equals(false) & t.deletedAt.isNull()))
        .get();
    return _lecteur.lire(_db.observations.actualTableName, rows,
        _mapper.versEntite, (r) => r.id);
  }

  @override
  Future<void> sauvegarder(Observation observation) async {
    await _db
        .into(_db.observations)
        .upsertConservantCreation(_mapper.versCompanion(observation));
  }

  @override
  Future<void> supprimer(String id) async {
    await (_db.update(_db.observations)..where((t) => t.id.equals(id))).write(
      ObservationsCompanion(
        deletedAt: Value(DateTime.now().toUtc().toIso8601String()),
      ),
    );
  }
}
