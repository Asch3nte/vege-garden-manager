import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/repositories/abstract_preferences_repository.dart';
import '../database/app_database.dart';
import '../mappers/preferences_mapper.dart';

/// drift-backed implementation of [AbstractPreferencesRepository].
///
/// The preferences are a single row (`id = 'singleton'`), seeded at database
/// creation; [sauvegarder] upserts it.
class PreferencesRepositoryImpl implements AbstractPreferencesRepository {
  final AppDatabase _db;
  final PreferencesMapper _mapper = const PreferencesMapper();

  PreferencesRepositoryImpl(this._db);

  @override
  Future<PreferencesUtilisateur> charger() async {
    final row = await (_db.select(_db.preferences)
          ..where((t) => t.id.equals(PreferencesUtilisateur.idSingleton)))
        .getSingleOrNull();
    return row == null ? PreferencesUtilisateur() : _mapper.versEntite(row);
  }

  @override
  Future<void> sauvegarder(PreferencesUtilisateur preferences) async {
    await _db
        .into(_db.preferences)
        .insertOnConflictUpdate(_mapper.versCompanion(preferences));
  }

  @override
  Future<void> reinitialiser() => sauvegarder(PreferencesUtilisateur());
}
