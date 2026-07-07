import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the test-time platform locale to French.
///
/// Every widget test asserts against French UI strings. Before the English
/// ARB (`app_en.arb`) existed, the app only had one supported locale, so
/// Flutter had no choice but to render French regardless of the test
/// runner's own system locale. Now that `en` is also supported, the default
/// locale-resolution algorithm picks whichever locale actually matches the
/// test machine — which may not be French. Pinning it here restores the
/// previous, environment-independent behaviour for the whole suite; tests
/// that specifically exercise locale switching (`locale_effective_test.dart`)
/// override it locally and clean up after themselves.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
  dispatcher.localeTestValue = const Locale('fr');
  dispatcher.localesTestValue = const [Locale('fr')];
  await testMain();
}
