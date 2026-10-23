// Widget tests for the Plus / Paramètres screen and its sub-panels.
//
// Overrides the preferences repository, then checks the settings root, the
// general panel (persisting a change), the privacy geoloc cycle and the
// notifications master gate.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/app/router.dart';
import 'package:pot_a_gerer/app/theme/couleurs_app.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/exceptions/preferences_illisibles_exception.dart';
import 'package:pot_a_gerer/domain/enums/langue.dart';
import 'package:pot_a_gerer/domain/enums/mode_geolocalisation.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_plus.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_a_propos.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_confidentialite.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/ecran_politique_confidentialite.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_general.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/widgets_parametres.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_notifications.dart';
import 'package:pot_a_gerer/domain/enums/grandeur_mesure.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';

import '../helpers/politique_fichiers.dart';

import '../helpers/globe.dart';

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
    when(() => repo.sontIllisibles()).thenAnswer((_) async => false);
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
            GoRoute(
              path: RoutesApp.plusPolitiqueSegment,
              builder: (context, state) =>
                  const EcranPolitiqueConfidentialite(),
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
          politiqueConfidentialiteSourceProvider
              .overrideWithValue(PolitiqueDepuisFichiers()),
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
    expect(find.text('Aide & lexique'), findsOneWidget);
    // « À propos » sits below the fold since the glossary row was added
    // — the lazy ListView needs a scroll to build it.
    await tester.scrollUntilVisible(find.text('À propos'), 100,
        scrollable: find.byType(Scrollable).first);
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

  testWidgets('general panel turns the deletion confirmation off',
      (tester) async {
    await monter(tester);
    await tester.tap(find.text('Préférences générales'));
    await tester.pumpAndSettle();

    final libelle = find.text('Confirmer suppressions et arrachages');
    await tester.scrollUntilVisible(libelle, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.descendant(
        of: find.ancestor(of: libelle, matching: find.byType(RangeeInterrupteur)),
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    expect((captured.last as PreferencesUtilisateur).confirmerSuppressions,
        isFalse);
  });

  group('units', () {
    Future<void> ouvrirGeneral(WidgetTester tester) async {
      await monter(tester);
      await tester.tap(find.text('Préférences générales'));
      await tester.pumpAndSettle();
    }

    PreferencesUtilisateur derniere() =>
        verify(() => repo.sauvegarder(captureAny())).captured.last
            as PreferencesUtilisateur;

    testWidgets('the preset sets every quantity', (tester) async {
      await ouvrirGeneral(tester);

      await tester.tap(find.text('Impérial'));
      await tester.pumpAndSettle();

      expect(derniere().unites.prereglage, SystemeUnites.imperial);
    });

    testWidgets('one quantity can differ, the preset then reads custom',
        (tester) async {
      when(() => repo.charger()).thenAnswer((_) async =>
          PreferencesUtilisateur(
              unites: const PreferencesUnites.uniforme(SystemeUnites.imperial)
                  .avec(GrandeurMesure.temperature, SystemeUnites.metrique)));
      await ouvrirGeneral(tester);

      expect(find.text('Personnalisé'), findsOneWidget);

      // A custom set opens the per-quantity section.
      await tester.ensureVisible(find.text('kg · g'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('kg · g'));
      await tester.pumpAndSettle();

      final unites = derniere().unites;
      expect(unites.pour(GrandeurMesure.masse), SystemeUnites.metrique);
      expect(unites.pour(GrandeurMesure.longueur), SystemeUnites.imperial);
    });
  });

  testWidgets('a failed preference save is reported', (tester) async {
    when(() => repo.sauvegarder(any()))
        .thenThrow(const FileSystemException('plein'));
    await monter(tester);

    await tester.tap(find.text('Préférences générales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Enregistrement impossible. Réessayez.'), findsOneWidget);
  });

  testWidgets('unreadable preferences are announced and stay locked',
      (tester) async {
    when(() => repo.sontIllisibles()).thenAnswer((_) async => true);
    when(() => repo.sauvegarder(any()))
        .thenThrow(PreferencesIllisiblesException());
    await monter(tester);

    expect(find.textContaining("n'ont pas pu être lues"), findsOneWidget);

    await tester.tap(find.text('Préférences générales'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Réglage non modifiable : tes préférences enregistrées sont illisibles.'),
        findsOneWidget);
  });

  testWidgets('a failed notification switch is reported', (tester) async {
    when(() => repo.sauvegarder(any()))
        .thenThrow(const FileSystemException('plein'));
    await monter(tester);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Enregistrement impossible. Réessayez.'), findsOneWidget);
  });

  testWidgets('privacy panel opens the embedded privacy policy',
      (tester) async {
    await monter(tester);
    await tester.tap(find.text('Confidentialité & opt-outs'));
    await tester.pumpAndSettle();

    final lien = find.text('Politique de confidentialité');
    await tester.scrollUntilVisible(lien, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(lien);
    await tester.pumpAndSettle();

    expect(find.text('En bref'), findsOneWidget);
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
    // Wide surface for the whole flow.
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

    // Tapping it opens the globe picker; picking a point and confirming
    // stores the position.
    await tester.tap(find.text('Position du potager'));
    await tester.pumpAndSettle();
    await choisirSurGlobe(tester, 5, 25);

    final potager =
        verify(() => potagers.sauvegarder(captureAny())).captured.last as Potager;
    expect(potager.localisation.estDefinie, isTrue);
  });

  testWidgets('privacy panel shows where the garden position comes from',
      (tester) async {
    when(() => repo.charger()).thenAnswer(
      (_) async =>
          PreferencesUtilisateur(modeGeolocalisation: ModeGeolocalisation.gps),
    );
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
        localisation: Localisation.gps(latitude: 50.61, longitude: 5.42),
      ),
    );
    when(() => potagers.obtenirTous()).thenAnswer((_) async => []);

    await monter(tester);
    await tester.tap(find.text('Confidentialité & opt-outs'));
    await tester.pumpAndSettle();

    expect(find.text('GPS · 50,6° N, 5,4° E'), findsOneWidget);
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

  testWidgets(
      'privacy panel lists the other gardens read-only, collapsed by '
      'default', (tester) async {
    when(() => repo.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(
        niveauExperience: NiveauExperience.intermediaire,
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
    when(() => potagers.obtenirTous()).thenAnswer(
      (_) async => [
        Potager(
          id: 'pot-1',
          nom: 'Mon potager',
          zoneClimatique:
              const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
          dateCreation: DateTime(2026, 1, 1),
        ),
        Potager(
          id: 'pot-2',
          nom: 'Jardin de la grand-mère',
          zoneClimatique: const ZoneClimatique(
              TypeClimat.mediterraneen, ZoneRusticite.zone9),
          dateCreation: DateTime(2026, 2, 1),
        ),
      ],
    );

    await monter(tester);
    await tester.tap(find.text('Confidentialité & opt-outs'));
    await tester.pumpAndSettle();

    // The other garden is listed by name; its details stay hidden until
    // expanded, and the active garden is not duplicated in the list.
    expect(find.text('Jardin de la grand-mère'), findsOneWidget);
    expect(find.text('Méditerranéen'), findsNothing);
    expect(find.text('Mon potager'), findsOneWidget);

    // Each garden block sits on its own contrasted surface.
    final actif = find.byKey(const ValueKey('bloc-potager-pot-1'));
    final autre = find.byKey(const ValueKey('bloc-potager-pot-2'));
    expect(find.descendant(of: actif, matching: find.text('Mon potager')),
        findsOneWidget);
    expect(find.descendant(of: actif, matching: find.text('Climat')),
        findsOneWidget);
    expect(
        find.descendant(
            of: autre, matching: find.text('Jardin de la grand-mère')),
        findsOneWidget);
    expect(tester.widget<Material>(actif).color,
        CouleursApp.surfaceAlterneeClair);

    await tester.tap(find.text('Jardin de la grand-mère'));
    await tester.pumpAndSettle();

    // Expanded: read-only rows, no chevron (non-interactive — no picker).
    expect(find.text('Méditerranéen'), findsOneWidget);
    await tester.tap(find.text('Méditerranéen'));
    await tester.pumpAndSettle();
    verifyNever(() => potagers.sauvegarder(any()));
  });

  testWidgets('a beginner does not see the other-gardens list',
      (tester) async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      ),
    );
    when(() => potagers.obtenirTous()).thenAnswer(
      (_) async => [
        Potager(
          id: 'pot-2',
          nom: 'Jardin de la grand-mère',
          zoneClimatique:
              const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
          dateCreation: DateTime(2026, 2, 1),
        ),
      ],
    );

    await monter(tester); // débutant by default

    await tester.tap(find.text('Confidentialité & opt-outs'));
    await tester.pumpAndSettle();

    expect(find.text('Jardin de la grand-mère'), findsNothing);
  });

  testWidgets('notifications master gates the categories', (tester) async {
    // Master off; intermediate level so the per-category toggles are shown
    // (they are an intermediate+ feature).
    when(() => repo.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(
        notificationsGlobalesActives: false,
        niveauExperience: NiveauExperience.intermediaire,
      ),
    );
    await monter(tester);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    // Every category switch is disabled while the master is off.
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    // First switch is the master (off, enabled); the rest are disabled.
    expect(switches.length, greaterThan(1));
    expect(switches.first.onChanged, isNotNull);
    expect(switches.skip(1).every((s) => s.onChanged == null), isTrue);
  });

  testWidgets('a beginner sees only the master notifications switch',
      (tester) async {
    // Default level is débutant → per-category toggles are hidden.
    await monter(tester);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(tester.widgetList<Switch>(find.byType(Switch)).length, 1);
  });
}
