import 'package:drift/drift.dart';

import '../../domain/entities/observation.dart';
import '../../domain/enums/cible_observation.dart';
import '../../domain/repositories/abstract_observation_repository.dart';
import '../database/app_database.dart';
import '../mappers/observation_mapper.dart';

/// drift-backed implementation of [AbstractObservationRepository].
class ObservationRepositoryImpl implements AbstractObservationRepository {
  final AppDatabase _db;
  final ObservationMapper _mapper = const ObservationMapper();

  ObservationRepositoryImpl(this._db);

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
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<List<Observation>> obtenirNonResolues() async {
    final rows = await (_db.select(_db.observations)
          ..where((t) => t.resolu.equals(false) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapper.versEntite).toList();
  }

  @override
  Future<void> sauvegarder(Observation observation) async {
    await _db
        .into(_db.observations)
        .insertOnConflictUpdate(_mapper.versCompanion(observation));
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
