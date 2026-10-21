import 'package:riverpod/riverpod.dart';

import '../../domain/value_objects/preferences_unites.dart';
import '../state/preferences_notifier.dart';

/// Display unit of each quantity; metric until the preferences are loaded.
final unitesProvider = Provider<PreferencesUnites>(
  (ref) =>
      ref.watch(preferencesProvider).value?.unites ?? const PreferencesUnites(),
);
