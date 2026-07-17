import '../value_objects/statistiques_stockage.dart';

/// Contract for reading local-storage statistics for the data-transparency
/// settings panel (docs/11 §6 — "Transparence des données").
///
/// Backed by the SQLite database in the infrastructure layer (per-table
/// `COUNT(*)` + the database page size); no network is involved — the figures
/// describe only what the app keeps on device.
abstract class AbstractStatistiquesDonneesService {
  /// Reads the current per-table record counts and the database's on-disk size.
  Future<StatistiquesStockage> obtenirStatistiques();
}
