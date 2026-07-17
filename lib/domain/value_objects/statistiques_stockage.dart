/// Row count of a single stored table (data-transparency view, docs/11 §6).
///
/// A plain, immutable pair — the table's real SQL name and how many records it
/// holds — surfaced so the user can see exactly what the app keeps on device.
///
/// Domain names are kept in French; the code is documented in English.
class StatistiqueTable {
  final String _nom;
  final int _lignes;

  const StatistiqueTable({required String nom, required int lignes})
      : assert(nom != ''),
        assert(lignes >= 0),
        _nom = nom,
        _lignes = lignes;

  /// The table's real SQL name (e.g. `plantations`).
  String get nom => _nom;

  /// Number of records stored in the table.
  int get lignes => _lignes;

  @override
  bool operator ==(Object other) =>
      other is StatistiqueTable && other._nom == _nom && other._lignes == _lignes;

  @override
  int get hashCode => Object.hash(_nom, _lignes);

  @override
  String toString() => 'StatistiqueTable($_nom, $_lignes)';
}

/// Immutable snapshot of what the app stores locally (docs/11 §6 — "Transparence
/// des données"): the per-table record counts plus the database's on-disk size.
///
/// A **result** value object assembled by an [AbstractStatistiquesDonneesService]
/// from the SQLite database; not persisted. It carries only structured data —
/// any human-facing formatting (byte units, labels) happens in the presentation
/// layer.
class StatistiquesStockage {
  final List<StatistiqueTable> _tables;
  final int _tailleOctets;

  StatistiquesStockage({
    required List<StatistiqueTable> tables,
    required int tailleOctets,
  })  : assert(tailleOctets >= 0),
        _tables = List.unmodifiable(tables),
        _tailleOctets = tailleOctets;

  /// Per-table record counts (unmodifiable, in the order provided).
  List<StatistiqueTable> get tables => _tables;

  /// The database file's size on disk, in bytes.
  int get tailleOctets => _tailleOctets;

  /// Total number of records across every table.
  int get totalLignes =>
      _tables.fold(0, (somme, t) => somme + t.lignes);

  @override
  String toString() =>
      'StatistiquesStockage(${_tables.length} tables, $totalLignes lignes, '
      '$_tailleOctets octets)';
}
