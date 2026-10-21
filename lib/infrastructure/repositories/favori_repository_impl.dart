import 'package:drift/drift.dart';

import '../../domain/repositories/abstract_favori_repository.dart';
import '../database/app_database.dart';

/// Drift implementation of [AbstractFavoriRepository].
///
/// Re-adding a removed favourite revives its row rather than inserting a new
/// one, so the creation date is kept.
class FavoriRepositoryImpl implements AbstractFavoriRepository {
  final AppDatabase _db;

  FavoriRepositoryImpl(this._db);

  @override
  Future<Set<String>> obtenirIds() async {
    final lignes = await (_db.select(
      _db.favoris,
    )..where((t) => t.deletedAt.isNull())).get();
    return Set.unmodifiable(lignes.map((l) => l.ficheId));
  }

  @override
  Future<void> ajouter(String ficheId) async {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    await _db
        .into(_db.favoris)
        .insert(
          FavorisCompanion.insert(
            ficheId: ficheId,
            createdAt: maintenant,
            updatedAt: maintenant,
          ),
          onConflict: DoUpdate(
            (_) => FavorisCompanion(
              updatedAt: Value(maintenant),
              deletedAt: const Value(null),
            ),
          ),
        );
  }

  @override
  Future<void> retirer(String ficheId) async {
    final maintenant = DateTime.now().toUtc().toIso8601String();
    await (_db.update(
      _db.favoris,
    )..where((t) => t.ficheId.equals(ficheId) & t.deletedAt.isNull())).write(
      FavorisCompanion(
        updatedAt: Value(maintenant),
        deletedAt: Value(maintenant),
      ),
    );
  }
}
