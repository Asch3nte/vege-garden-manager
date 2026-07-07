// Widget tests for the `locale` wiring on [PotAGererApp] (docs/15 §6 —
// "Langue effective"): the stored `Langue` preference must drive the actual
// app locale instead of being persisted but inert.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/langue.dart';
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

void main() {
  // Same minimal-mocking shell as navigation_test.dart: only the Accueil tab
  // needs to resolve for `Localizations.localeOf` to be readable.
  Future<void> pomperA(WidgetTester tester, Langue langue) async {
    final potagers = _MockPotagers();
    final parcelles = _MockParcelles();
    final taches = _MockTaches();
    final preferences = _MockPreferences();
    final fiches = _MockFiches();
    final familles = _MockFamilles();
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => preferences.charger()).thenAnswer(
      (_) async =>
          PreferencesUtilisateur(onboardingTermine: true, langue: langue),
    );
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

  testWidgets('Langue.fr resolves to the French locale', (tester) async {
    await pomperA(tester, Langue.fr);

    final locale =
        Localizations.localeOf(tester.element(find.byType(Scaffold).first));
    expect(locale, const Locale('fr'));
  });

  testWidgets('Langue.en resolves to the English locale', (tester) async {
    await pomperA(tester, Langue.en);

    final locale =
        Localizations.localeOf(tester.element(find.byType(Scaffold).first));
    expect(locale, const Locale('en'));
  });

  testWidgets('Langue.auto follows the platform locale', (tester) async {
    // WidgetsApp resolves the locale from the plural `locales` list, so both
    // test values must be set for the override to actually take effect.
    tester.platformDispatcher.localeTestValue = const Locale('en');
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pomperA(tester, Langue.auto);

    final locale =
        Localizations.localeOf(tester.element(find.byType(Scaffold).first));
    expect(locale, const Locale('en'));
  });
}
