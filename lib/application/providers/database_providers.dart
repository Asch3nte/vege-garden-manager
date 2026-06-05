import 'package:riverpod/riverpod.dart';

import '../../infrastructure/database/app_database.dart';

/// Provides the application's [AppDatabase].
///
/// It has **no default**: opening the database needs a platform-specific
/// connection (file path), which is a bootstrap concern. The app overrides this
/// provider at startup with a real instance, and tests override it with an
/// in-memory database (`NativeDatabase.memory()`), so the rest of the providers
/// stay platform-agnostic.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden with an AppDatabase instance '
    '(at app startup, or in tests).',
  );
});
