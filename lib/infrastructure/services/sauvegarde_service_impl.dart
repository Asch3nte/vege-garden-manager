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

    try {
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
          final connues = {for (final c in table.$columns) c.name};
          for (final row in rows) {
            if (row is! Map || row.isEmpty) {
              throw SauvegardeInvalideException(
                'Malformed row in table "${table.actualTableName}".',
              );
            }
            await _fusionnerLigne(table, connues, row.cast<String, dynamic>());
          }
        }
      });
    } on SauvegardeInvalideException {
      rethrow;
    } on Exception catch (e) {
      throw SauvegardeInvalideException(
        'Backup rows could not be written to the database.',
        cause: e,
      );
    }
  }

  /// Upserts one raw row into [table]: a primary-key conflict updates the
  /// existing row in place (its children keep their parent); a conflict on
  /// another unique key keeps the local row.
  ///
  /// Column names come from the file, so they are checked against [connues]
  /// before being written into the SQL text.
  Future<void> _fusionnerLigne(
    TableInfo<Table, dynamic> table,
    Set<String> connues,
    Map<String, dynamic> row,
  ) {
    final colonnes = row.keys.toList();
    for (final colonne in colonnes) {
      if (!connues.contains(colonne)) {
        throw SauvegardeInvalideException(
          'Unknown column "$colonne" in table "${table.actualTableName}".',
        );
      }
      final valeur = row[colonne];
      if (valeur != null &&
          valeur is! num &&
          valeur is! String &&
          valeur is! bool) {
        throw SauvegardeInvalideException(
          'Unsupported value for "$colonne" in table "${table.actualTableName}".',
        );
      }
    }
    final cle = table.$primaryKey.map((c) => '"${c.name}"').join(', ');
    final placeholders = List.filled(colonnes.length, '?').join(', ');
    final affectations = colonnes.map((c) => '"$c" = excluded."$c"').join(', ');
    final sql =
        'INSERT INTO "${table.actualTableName}" '
        '(${colonnes.map((c) => '"$c"').join(', ')}) VALUES ($placeholders) '
        'ON CONFLICT ($cle) DO UPDATE SET $affectations '
        'ON CONFLICT DO NOTHING';
    final variables = colonnes.map((c) => Variable<Object>(row[c])).toList();
    return _db.customInsert(sql, variables: variables);
  }
}
