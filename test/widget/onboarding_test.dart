// Widget tests for the first-launch onboarding gate (docs/15 §7).
//
// Mounts [PotAGererApp] through the real router: while the onboarding-completion
// preference is false, the router redirects every location onto the onboarding
// flow; completing it lifts the gate and lands on Accueil. The repositories are
// overridden so the Accueil branch builds instantly (it is reached after the
// gate opens).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_famille_botanique_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/main.dart';

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _MockFiches extends Mock implements AbstractFichePlanteRepository {}

class _MockFamilles extends Mock implements AbstractFamilleBotaniqueRepository {}

class _FakePrefs extends Fake implements PreferencesUtilisateur {}

class _FakePotager extends Fake implements Potager {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrefs());
    registerFallbackValue(_FakePotager());
  });

  /// Mounts the app with [onboardingTermine] as the initial preference value.
  /// [saved] captures the persisted preferences so a completion can be asserted.
  Future<void> monter(
    WidgetTester tester, {
    required bool onboardingTermine,
    List<PreferencesUtilisateur>? saved,
    Size taille = const Size(390, 800),
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final potagers = _MockPotagers();
    final parcelles = _MockParcelles();
    final taches = _MockTaches();
    final preferences = _MockPreferences();
    final fiches = _MockFiches();
    final familles = _MockFamilles();
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => potagers.obtenirTous()).thenAnswer((_) async => []);
    when(() => potagers.sauvegarder(any())).thenAnswer((_) async {});
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => preferences.charger()).thenAnswer(
        (_) async => PreferencesUtilisateur(onboardingTermine: onboardingTermine));
    when(() => preferences.sauvegarder(any())).thenAnswer((invocation) async {
      saved?.add(invocation.positionalArguments.first as PreferencesUtilisateur);
    });
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => []);
    when(() => familles.obtenirToutes()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          tacheRepositoryProvider.overrideWithValue(taches),
          preferencesRepositoryProvider.overrideWithValue(preferences),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          familleBotaniqueRepositoryProvider
              .overrideWith((ref) async => familles),
        ],
        child: const PotAGererApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first launch is gated on the onboarding screen', (tester) async {
    await monter(tester, onboardingTermine: false);

    expect(find.text("Bienvenue dans Pot'à Gérer"), findsOneWidget);
    // The navigation shell (and its Accueil app bar) is not reachable yet.
    expect(find.widgetWithText(AppBar, 'Accueil'), findsNothing);
  });

  testWidgets('walking the whole flow creates the garden and lifts the gate',
      (tester) async {
    final saved = <PreferencesUtilisateur>[];
    // Wide surface so the map's region band fits without horizontal scrolling.
    await monter(tester,
        onboardingTermine: false, saved: saved, taille: const Size(1600, 800));

    // Step 0 welcome → step 1 privacy → step 2 position.
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    // Step 2: a position is required. Pick one on the world map.
    await tester.tap(find.text('Choisir sur la carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone tropicale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    // Step 2 → 3 climate → 4 garden.
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    // Step 4: name the first garden, then → step 5 notifications → finish.
    await tester.enterText(find.byType(TextField), 'Mon potager');
    await tester.pump();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    // The garden was created and the gate opened onto the shell (Accueil).
    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);
    expect(saved.last.onboardingTermine, isTrue);
  });

  testWidgets('an already-onboarded launch skips straight to Accueil',
      (tester) async {
    await monter(tester, onboardingTermine: true);

    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);
    expect(find.text("Bienvenue dans Pot'à Gérer"), findsNothing);
  });
}
