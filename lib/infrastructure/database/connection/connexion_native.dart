import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_database.dart';

/// Opens the application's persistent SQLite database on a real device/desktop.
///
/// The file lives in the platform's application-support directory (private to
/// the app, never on external/shared storage — privacy by design). Opening is
/// **lazy** so the path lookup runs off the UI thread on first query, and the
/// connection is created in a background isolate
/// ([NativeDatabase.createInBackground]) to keep the UI smooth.
///
/// Native SQLite libraries are bundled by `package:sqlite3` build hooks. Kept out
/// of [AppDatabase] so the database stays testable with `NativeDatabase.memory()`.
AppDatabase ouvrirBaseAppli() {
  final executor = LazyDatabase(() async {
    final dossier = await getApplicationSupportDirectory();
    final fichier = File(p.join(dossier.path, 'pot_a_gerer.sqlite'));
    return NativeDatabase.createInBackground(fichier);
  });
  return AppDatabase(executor);
}
