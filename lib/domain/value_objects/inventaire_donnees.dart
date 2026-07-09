/// One line of the local-data inventory: a stored table and how many records it
/// holds. [table] is the raw SQL table name (stable across locales); the UI maps
/// it to a human label.
class EntreeInventaire {
  final String _table;
  final int _nombre;

  const EntreeInventaire._(this._table, this._nombre);

  factory EntreeInventaire({required String table, required int nombre}) {
    assert(nombre >= 0, 'record count must not be negative');
    return EntreeInventaire._(table, nombre);
  }

  /// Raw SQL table name (e.g. `plantations`).
  String get table => _table;

  /// Number of records stored in the table.
  int get nombre => _nombre;
}

/// A read-only inventory of everything stored **locally** on the device
/// (data-transparency screen, docs/15 §6). Pure data — no access journal is
/// kept: nothing is ever transmitted, so there is no third party to audit.
class InventaireDonnees {
  final List<EntreeInventaire> _entrees;

  InventaireDonnees(List<EntreeInventaire> entrees)
      : _entrees = List.unmodifiable(entrees);

  /// The per-table entries (immutable).
  List<EntreeInventaire> get entrees => _entrees;

  /// Total number of records across every table.
  int get total => _entrees.fold(0, (acc, e) => acc + e.nombre);
}
