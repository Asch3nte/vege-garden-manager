import '../../domain/repositories/abstract_statistiques_donnees_service.dart';
import '../../domain/value_objects/statistiques_stockage.dart';
import '../database/app_database.dart';

/// drift-backed [AbstractStatistiquesDonneesService].
///
/// Counts are read **generically** from [AppDatabase.allTables] (one
/// `COUNT(*)` per table), so new tables appear automatically without touching
/// this service. The on-disk size is derived from SQLite's own page bookkeeping
/// (`page_count * page_size`) rather than the file system, which keeps the
/// service platform-agnostic and testable against an in-memory database.
class StatistiquesDonneesServiceImpl
    implements AbstractStatistiquesDonneesService {
  final AppDatabase _db;

  StatistiquesDonneesServiceImpl(this._db);

  @override
  Future<StatistiquesStockage> obtenirStatistiques() async {
    final tables = <StatistiqueTable>[];
    for (final table in _db.allTables) {
      final nom = table.actualTableName;
      // The name comes from the schema (never user input) — safe to interpolate.
      final row = await _db
          .customSelect('SELECT COUNT(*) AS c FROM "$nom"')
          .getSingle();
      tables.add(StatistiqueTable(nom: nom, lignes: row.read<int>('c')));
    }
    tables.sort((a, b) => a.nom.compareTo(b.nom));

    final tailleRow = await _db
        .customSelect('SELECT page_count * page_size AS octets '
            'FROM pragma_page_count(), pragma_page_size()')
        .getSingle();

    return StatistiquesStockage(
      tables: tables,
      tailleOctets: tailleRow.read<int>('octets'),
    );
  }
}
