// Widget tests for the Plus / Paramètres screen and its sub-panels.
//
// Overrides the preferences repository, then checks the settings root, the
// general panel (persisting a change), the privacy geoloc cycle and the
// notifications master gate.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/langue.dart';
import 'package:pot_a_gerer/domain/enums/mode_geolocalisation.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_plus.dart';

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _FakePrefs extends Fake implements PreferencesUtilisateur {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePrefs()));

  late MockPreferences repo;

  setUp(() {
    repo = MockPreferences();
    when(() => repo.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranPlus(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings root lists the categories', (tester) async {
    await monter(tester);

    expect(find.text('Préférences générales'), findsOneWidget);
    expect(find.text('Confidentialité & opt-outs'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('À propos'), findsOneWidget);
  });

  testWidgets('general panel persists a language change', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Préférences générales'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    expect((captured.last as PreferencesUtilisateur).langue, Langue.en);
  });

  testWidgets('privacy panel cycles the geolocation mode', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Confidentialité & opt-outs'));
    await tester.pumpAndSettle();

    // Default is "Désactivée"; tapping the row cycles to "Manuelle".
    expect(find.text('Désactivée'), findsOneWidget);
    await tester.tap(find.text('Géolocalisation'));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    expect(
      (captured.last as PreferencesUtilisateur).modeGeolocalisation,
      ModeGeolocalisation.manuelle,
    );
  });

  testWidgets('notifications master gates the categories', (tester) async {
    // Start with the master switch off.
    when(() => repo.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(notificationsGlobalesActives: false),
    );
    await monter(tester);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    // Every category switch is disabled while the master is off.
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    // First switch is the master (off, enabled); the rest are disabled.
    expect(switches.first.onChanged, isNotNull);
    expect(switches.skip(1).every((s) => s.onChanged == null), isTrue);
  });
}
