import '../../domain/entities/preferences_utilisateur.dart';
import '../../domain/exceptions/preferences_illisibles_exception.dart';
import '../../domain/repositories/abstract_preferences_repository.dart';
import '../database/app_database.dart';
import '../database/lecteur_lignes.dart';
import '../mappers/preferences_mapper.dart';

/// drift-backed implementation of [AbstractPreferencesRepository].
///
/// The preferences are a single row (`id = 'singleton'`), seeded at database
/// creation; [sauvegarder] upserts it.
class PreferencesRepositoryImpl implements AbstractPreferencesRepository {
  final AppDatabase _db;
  final PreferencesMapper _mapper = const PreferencesMapper();
  final LecteurLignes _lecteur;

  PreferencesRepositoryImpl(this._db, {this._lecteur = const LecteurLignes()});

  Future<PreferencesRow?> _ligne() => (_db.select(_db.preferences)
        ..where((t) => t.id.equals(PreferencesUtilisateur.idSingleton)))
      .getSingleOrNull();

  PreferencesUtilisateur? _lire(PreferencesRow ligne) => _lecteur.lireUne(
      _db.preferences.actualTableName, ligne, _mapper.versEntite, (r) => r.id);

  @override
  Future<PreferencesUtilisateur> charger() async {
    final ligne = await _ligne();
    if (ligne == null) return PreferencesUtilisateur();
    return _lire(ligne) ?? PreferencesUtilisateur.prudentes();
  }

  @override
  Future<bool> sontIllisibles() async {
    final ligne = await _ligne();
    return ligne != null && _lire(ligne) == null;
  }

  @override
  Future<void> sauvegarder(PreferencesUtilisateur preferences) async {
    if (await sontIllisibles()) throw PreferencesIllisiblesException();
    await _db
        .into(_db.preferences)
        .insertOnConflictUpdate(_mapper.versCompanion(preferences));
  }

  @override
  Future<void> reinitialiser() => sauvegarder(PreferencesUtilisateur());
}
