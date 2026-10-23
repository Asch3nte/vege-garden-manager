// Widget tests for the embedded privacy policy screen.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_ouverture_lien_service.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/ecran_politique_confidentialite.dart';

class _MockOuvertureLien extends Mock implements AbstractOuvertureLienService {}

void main() {
  setUpAll(() => registerFallbackValue(Uri.parse('https://example.org')));

  late _MockOuvertureLien liens;

  setUp(() {
    liens = _MockOuvertureLien();
    when(() => liens.ouvrir(any())).thenAnswer((_) async => true);
  });

  Future<void> monter(WidgetTester tester, Locale langue) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ouvertureLienServiceProvider.overrideWithValue(liens),
          // Synchronous read: the asset bundle's real I/O never completes
          // under the test clock.
          lectureAssetTexteProvider.overrideWithValue(
              (chemin) async => File(chemin).readAsStringSync()),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          locale: langue,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranPolitiqueConfidentialite(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the French policy, without repeating its title',
      (tester) async {
    await monter(tester, const Locale('fr'));

    expect(find.text('Politique de confidentialité'), findsOneWidget);
    expect(find.text('En bref'), findsOneWidget);
  });

  testWidgets('shows the English policy in English', (tester) async {
    await monter(tester, const Locale('en'));

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('In short'), findsOneWidget);
  });

  testWidgets('a link opens through the link service', (tester) async {
    await monter(tester, const Locale('fr'));

    await tester.ensureVisible(find.textContaining("Conditions d'Open-Meteo",
        findRichText: true));
    await tester.pumpAndSettle();
    await tester.tapOnText(find.textRange.ofSubstring("Conditions d'Open-Meteo"));

    verify(() => liens.ouvrir(Uri.parse('https://open-meteo.com/en/terms')))
        .called(1);
  });

  test('both policies are declared as assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final suffixe in ['', '.en']) {
      expect(pubspec, contains('- docs/politique-confidentialite$suffixe.md'));
    }
  });
}
