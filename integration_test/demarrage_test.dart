import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';

import 'support/app_de_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch shows onboarding', (tester) async {
    await lancerApp(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Navigator).first),
    )!;
    expect(find.text(l10n.onboardingBienvenueTitre), findsOneWidget);
  });
}
