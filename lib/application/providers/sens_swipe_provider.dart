import 'package:riverpod/riverpod.dart';

import '../../domain/enums/sens_swipe.dart';
import '../state/preferences_notifier.dart';

/// Swipe direction of the lists; standard until the preferences are loaded.
final sensSwipeProvider = Provider<SensSwipe>(
  (ref) => ref.watch(preferencesProvider).value?.sensSwipe ?? SensSwipe.standard,
);
