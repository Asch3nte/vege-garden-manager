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
/// The SQLite native libraries are bundled by `sqlite3_flutter_libs` (declared
/// in `pubspec.yaml`); no Dart-side call is needed for that. This is a bootstrap
/// concern, kept out of [AppDatabase] itself so the database stays
/// platform-agnostic and testable with `NativeDatabase.memory()`.
AppDatabase ouvrirBaseAppli() {
  final executor = LazyDatabase(() async {
    final dossier = await getApplicationSupportDirectory();
    final fichier = File(p.join(dossier.path, 'pot_a_gerer.sqlite'));
    return NativeDatabase.createInBackground(fichier);
  });
  return AppDatabase(executor);
}
