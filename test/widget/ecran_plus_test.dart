// Widget tests for the Plus / Paramètres screen and its sub-panels.
//
// Overrides the preferences repository, then checks the settings root, the
// general panel (persisting a change), the privacy geoloc cycle and the
// notifications master gate.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/router.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/langue.dart';
import 'package:pot_a_gerer/domain/enums/mode_geolocalisation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_plus.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_a_propos.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_confidentialite.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_general.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_notifications.dart';

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class _FakePrefs extends Fake implements PreferencesUtilisateur {}

class _FakePotager extends Fake implements Potager {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrefs());
    registerFallbackValue(_FakePotager());
  });

  late MockPreferences repo;
  late MockPotagers potagers;

  setUp(() {
    repo = MockPreferences();
    potagers = MockPotagers();
    when(() => repo.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
    // No active garden → the privacy panel's position row reads "none".
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
  });

  Future<void> monter(WidgetTester tester) async {
    // The sub-panels are go_router sub-routes of /plus, so the screen needs a
    // router (not a plain MaterialApp) to navigate to them.
    final router = GoRouter(
      initialLocation: RoutesApp.plus,
      routes: [
        GoRoute(
          path: RoutesApp.plus,
          builder: (context, state) => const EcranPlus(),
          routes: [
            GoRoute(
              path: RoutesApp.plusGeneralSegment,
              builder: (context, state) => const PanneauGeneral(),
            ),
            GoRoute(
              path: RoutesApp.plusConfidentialiteSegment,
              builder: (context, state) => const PanneauConfidentialite(),
            ),
            GoRoute(
              path: RoutesApp.plusNotificationsSegment,
              builder: (context, state) => const PanneauNotifications(),
            ),
            GoRoute(
              path: RoutesApp.plusAProposSegment,
              builder: (context, state) => const PanneauAPropos(),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(repo),
          potagerRepositoryProvider.overrideWithValue(potagers),
        ],
        child: MaterialApp.router(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
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

    // Default is "Aucune" (off); tapping the row cycles to "Région" (manual).
    expect(find.text('Aucune'), findsOneWidget);
    await tester.tap(find.text('Géolocalisation'));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    expect(
      (captured.last as PreferencesUtilisateur).modeGeolocalisation,
      ModeGeolocalisation.manuelle,
    );
  });

  testWidgets('privacy panel sets the garden position (manual mode)',
      (tester) async {
    // Wide surface so the map's region band fits without horizontal scrolling.
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => repo.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(
        modeGeolocalisation: ModeGeolocalisation.manuelle,
      ),
    );
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      ),
    );
    when(() => potagers.sauvegarder(any())).thenAnswer((_) async {});
    when(() => potagers.obtenirTous()).thenAnswer((_) async => []);

    await monter(tester);
    await tester.tap(find.text('Confidentialité & opt-outs'));
    await tester.pumpAndSettle();

    // The position row is shown (manual mode) with the "none" status.
    expect(find.text('Position du potager'), findsOneWidget);
    expect(find.text('Aucune — touchez pour la définir'), findsOneWidget);

    // Tapping it opens the world map; jumping to a region and confirming
    // stores the position.
    await tester.tap(find.text('Position du potager'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone tropicale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final potager =
        verify(() => potagers.sauvegarder(captureAny())).captured.last as Potager;
    expect(potager.localisation.estDefinie, isTrue);
  });

  testWidgets('privacy panel edits the active garden climate', (tester) async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      ),
    );
    when(() => potagers.sauvegarder(any())).thenAnswer((_) async {});
    when(() => potagers.obtenirTous()).thenAnswer((_) async => []);

    await monter(tester);
    await tester.tap(find.text('Confidentialité & opt-outs'));
    await tester.pumpAndSettle();

    // The climate row shows the current value (even with geoloc off).
    expect(find.text('Océanique'), findsOneWidget);

    // Tapping opens the descriptive picker; choosing another climate persists it.
    await tester.tap(find.text('Climat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Méditerranéen'));
    await tester.pumpAndSettle();

    final potager =
        verify(() => potagers.sauvegarder(captureAny())).captured.last as Potager;
    expect(potager.zoneClimatique.type, TypeClimat.mediterraneen);
    expect(potager.zoneClimatique.rusticite, ZoneRusticite.zone8); // preserved
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
