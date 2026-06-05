import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/enums/mode_import.dart';
import '../../domain/exceptions/sauvegarde_invalide_exception.dart';
import '../../domain/repositories/abstract_sauvegarde_service.dart';
import '../database/app_database.dart';

/// drift-backed implementation of [AbstractSauvegardeService].
///
/// Backup is **generic**: every table in [AppDatabase.allTables] is dumped via
/// raw `SELECT *`, so the format follows the schema automatically (no per-table
/// code to maintain). The JSON envelope carries the `schemaVersion`; an import
/// from a different version is rejected rather than silently corrupting data.
///
/// The schema has no BLOB columns in V1 (photos are V1.1), so every value is
/// JSON-encodable. All work happens locally; the produced/consumed JSON never
/// leaves the device through this service.
class SauvegardeServiceImpl implements AbstractSauvegardeService {
  final AppDatabase _db;

  SauvegardeServiceImpl(this._db);

  @override
  Future<String> exporterJson() async {
    final tables = <String, dynamic>{};
    for (final table in _db.allTables) {
      final rows =
          await _db.customSelect('SELECT * FROM ${table.actualTableName}').get();
      tables[table.actualTableName] = rows.map((r) => r.data).toList();
    }
    return jsonEncode({
      'schemaVersion': _db.schemaVersion,
      'exporteLe': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
    });
  }

  @override
  Future<void> importerJson(String json, ModeImport mode) async {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      throw SauvegardeInvalideException('Backup is not valid JSON.', cause: e);
    }

    if (envelope['schemaVersion'] != _db.schemaVersion) {
      throw SauvegardeInvalideException(
        'Unsupported backup schema version: ${envelope['schemaVersion']} '
        '(expected ${_db.schemaVersion}).',
      );
    }
    final tables = envelope['tables'];
    if (tables is! Map<String, dynamic>) {
      throw SauvegardeInvalideException('Backup is missing its "tables" map.');
    }

    await _db.transaction(() async {
      if (mode == ModeImport.remplacer) {
        // Delete children before parents to satisfy ON DELETE RESTRICT FKs.
        for (final table in _db.allTables.toList().reversed) {
          await _db.customStatement('DELETE FROM ${table.actualTableName}');
        }
      }
      // Insert parents before children (declaration order).
      for (final table in _db.allTables) {
        final rows = tables[table.actualTableName];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is! Map) {
            throw SauvegardeInvalideException(
              'Malformed row in table "${table.actualTableName}".',
            );
          }
          await _insererBrut(
            table.actualTableName,
            row.cast<String, dynamic>(),
          );
        }
      }
    });
  }

  /// Inserts (or replaces, keyed by primary key) one raw row into [table].
  Future<void> _insererBrut(String table, Map<String, dynamic> row) {
    final colonnes = row.keys.toList();
    final placeholders = List.filled(colonnes.length, '?').join(', ');
    final sql = 'INSERT OR REPLACE INTO $table '
        '(${colonnes.join(', ')}) VALUES ($placeholders)';
    final variables = colonnes.map((c) => Variable<Object>(row[c])).toList();
    return _db.customInsert(sql, variables: variables);
  }
}
