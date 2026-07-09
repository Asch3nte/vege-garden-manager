import '../../domain/repositories/abstract_inventaire_donnees_service.dart';
import '../../domain/value_objects/inventaire_donnees.dart';
import '../database/app_database.dart';

/// drift-backed [AbstractInventaireDonneesService].
///
/// Generic, like the factory reset: it walks [AppDatabase.allTables] and runs a
/// `SELECT COUNT(*)` on each, so a newly added table appears in the inventory
/// automatically (nothing stored is ever hidden from the user).
class InventaireDonneesServiceImpl implements AbstractInventaireDonneesService {
  final AppDatabase _db;

  InventaireDonneesServiceImpl(this._db);

  @override
  Future<InventaireDonnees> obtenir() async {
    final entrees = <EntreeInventaire>[];
    for (final table in _db.allTables) {
      final nom = table.actualTableName;
      final ligne = await _db
          .customSelect('SELECT COUNT(*) AS n FROM $nom')
          .getSingle();
      entrees.add(EntreeInventaire(table: nom, nombre: ligne.read<int>('n')));
    }
    return InventaireDonnees(entrees);
  }
}
