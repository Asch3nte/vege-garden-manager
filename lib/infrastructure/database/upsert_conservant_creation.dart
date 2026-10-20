import 'package:drift/drift.dart';

/// Upsert that never rewrites the creation columns of an existing row.
extension UpsertConservantCreation<T extends Table, D> on InsertStatement<T, D> {
  static const _colonnesCreation = {'created_at', 'date_creation'};

  /// Inserts [ligne], or updates the row with the same primary key while
  /// keeping its `created_at` and `date_creation`.
  Future<int> upsertConservantCreation(UpdateCompanion<D> ligne) {
    final miseAJour = Map.of(ligne.toColumns(false))
      ..removeWhere((colonne, _) => _colonnesCreation.contains(colonne));
    return insert(
      ligne,
      onConflict: DoUpdate((_) => RawValuesInsertable<D>(miseAJour)),
    );
  }
}
