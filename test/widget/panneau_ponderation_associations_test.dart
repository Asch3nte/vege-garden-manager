// Widget test for the expert association-weighting panel (ADR-0011).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/poids_association.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_ponderation_associations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/widgets_parametres.dart';

class _MockPrefs extends Mock implements AbstractPreferencesRepository {}

class _FakePrefs extends Fake implements PreferencesUtilisateur {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePrefs()));

  late _MockPrefs prefs;

  setUp(() {
    prefs = _MockPrefs();
    when(() => prefs.charger()).thenAnswer(
        (_) async => PreferencesUtilisateur(
            niveauExperience: NiveauExperience.expert));
    when(() => prefs.sauvegarder(any())).thenAnswer((_) async {});
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesRepositoryProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PanneauPonderationAssociations(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the five effect families and the note', (tester) async {
    await monter(tester);
    expect(find.text('Gain de place'), findsOneWidget);
    expect(find.text('Protection (ravageurs)'), findsOneWidget);
    expect(find.text('Fertilité du sol'), findsOneWidget);
    expect(find.text('Pollinisation'), findsOneWidget);
    expect(find.text('Couverture & abri'), findsOneWidget);
  });

  testWidgets('setting a family weight persists it', (tester) async {
    await monter(tester);

    final zone = find.ancestor(
        of: find.text('Gain de place'), matching: find.byType(ChampEmpile));
    await tester
        .tap(find.descendant(of: zone, matching: find.text('Ignorer')));
    await tester.pumpAndSettle();

    final captured = verify(() => prefs.sauvegarder(captureAny())).captured;
    final dernier = captured.last as PreferencesUtilisateur;
    expect(
        dernier.ponderationAssociations
            .poids(FamilleEffetAssociation.gainDePlace),
        PoidsAssociation.ignore);
  });

  testWidgets('reset is disabled by default and restores the defaults',
      (tester) async {
    await monter(tester);
    await tester.scrollUntilVisible(
        find.text('Réinitialiser les poids'), 200,
        scrollable: find.byType(Scrollable).first);

    // Default profile → reset disabled.
    OutlinedButton reset() => tester.widget<OutlinedButton>(find.ancestor(
        of: find.text('Réinitialiser les poids'),
        matching: find.byType(OutlinedButton)));
    expect(reset().onPressed, isNull);

    // Change the last family (visible next to the button) → reset enabled.
    final zone = find.ancestor(
        of: find.text('Couverture & abri'), matching: find.byType(ChampEmpile));
    await tester.tap(find.descendant(of: zone, matching: find.text('Fort')));
    await tester.pumpAndSettle();
    expect(reset().onPressed, isNotNull);

    await tester.tap(find.text('Réinitialiser les poids'));
    await tester.pumpAndSettle();

    final captured = verify(() => prefs.sauvegarder(captureAny())).captured;
    expect(
        (captured.last as PreferencesUtilisateur)
            .ponderationAssociations
            .estDefaut,
        isTrue);
  });
}
