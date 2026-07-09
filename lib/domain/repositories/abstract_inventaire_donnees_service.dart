import '../value_objects/inventaire_donnees.dart';

/// Reads a read-only inventory of the locally stored data — how many records
/// each table holds — for the data-transparency screen (docs/15 §6).
///
/// Purely introspective: it counts, it never mutates, and it keeps **no access
/// journal** (a 100%-local app has no third party to audit; a journal would only
/// store more personal data).
abstract class AbstractInventaireDonneesService {
  /// Counts the records of every stored table.
  Future<InventaireDonnees> obtenir();
}
