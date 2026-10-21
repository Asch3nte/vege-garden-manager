import 'package:riverpod/riverpod.dart';

import '../../domain/enums/langue.dart';
import '../state/preferences_notifier.dart';

/// Language code of the device among the supported ones; overridden at startup.
final codeLangueSystemeProvider = Provider<String>((ref) => 'fr');

/// Language code of the texts and content shown to the user: the language
/// preference, or the device language when it is `auto`.
final codeLangueProvider = Provider<String>((ref) {
  final langue = ref.watch(preferencesProvider).value?.langue ?? Langue.auto;
  return switch (langue) {
    Langue.fr => 'fr',
    Langue.en => 'en',
    Langue.auto => ref.watch(codeLangueSystemeProvider),
  };
});
