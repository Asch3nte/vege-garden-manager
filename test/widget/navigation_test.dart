// Widget tests for the primary navigation shell.
//
// Exercises [PotAGererApp] directly (not [main]), so it needs no platform
// bootstrap (database, timezone, notifications). It checks the app mounts on the
// Accueil tab, that the layout is responsive (bottom bar vs rail around the
// 600px breakpoint), and that selecting a destination switches the screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/main.dart';

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

void main() {
  // The Accueil tab is a real ConsumerWidget reading the repositories, so the
  // app needs a ProviderScope with empty-returning repos. In production the
  // scope is supplied by Bootstrap; here we override it directly. Navigation
  // chrome (the focus of these tests) is independent of the data.
  Future<void> pomperA(WidgetTester tester, Size taille) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final potagers = _MockPotagers();
    final parcelles = _MockParcelles();
    final taches = _MockTaches();
    final preferences = _MockPreferences();
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          tacheRepositoryProvider.overrideWithValue(taches),
          preferencesRepositoryProvider.overrideWithValue(preferences),
        ],
        child: PotAGererApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile width shows a bottom bar with the five destinations',
      (tester) async {
    await pomperA(tester, const Size(390, 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final libelle in const [
      'Accueil',
      'Potager',
      'Catalogue',
      'Calendrier',
      'Plus',
    ]) {
      expect(find.text(libelle), findsWidgets, reason: 'onglet $libelle');
    }

    // Accueil is the initial branch.
    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);
  });

  testWidgets('tablet width shows a rail instead of the bottom bar',
      (tester) async {
    await pomperA(tester, const Size(900, 700));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('selecting a destination switches the active screen',
      (tester) async {
    await pomperA(tester, const Size(390, 800));

    // Tap the "Catalogue" label in the bottom bar.
    await tester.tap(find.text('Catalogue'));
    await tester.pumpAndSettle();

    // The Catalogue screen's app bar is now shown…
    expect(find.widgetWithText(AppBar, 'Catalogue'), findsOneWidget);
    // …and the Accueil app bar is no longer the visible one.
    expect(find.widgetWithText(AppBar, 'Accueil'), findsNothing);
  });
}
