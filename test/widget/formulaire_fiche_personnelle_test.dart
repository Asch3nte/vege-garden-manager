// Widget tests for the personal-sheet form: a successful creation (the built
// model reaches the repository) and validation blocking a save with empty
// required fields and multi-selects.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante_personnelle.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_fiche_personnelle.dart';

class MockFichesPerso extends Mock
    implements AbstractFichePlantePersonnelleRepository {}

class _FausseFiche extends Fake implements FichePlantePersonnelle {}

void main() {
  late MockFichesPerso repo;

  setUpAll(() => registerFallbackValue(_FausseFiche()));

  setUp(() {
    repo = MockFichesPerso();
    when(() => repo.obtenirToutes()).thenAnswer((_) async => []);
    when(() => repo.obtenirParIdFiche(any())).thenAnswer((_) async => null);
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
  });

  Future<void> monter(WidgetTester tester) async {
    // A tall viewport so the whole form list is built (no scrolling needed).
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlantePersonnelleRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FormulaireFichePersonnelle(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> saisir(WidgetTester tester, String label, String valeur) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, label),
      valeur,
    );
  }

  testWidgets('fills the form and saves a new sheet', (tester) async {
    await monter(tester);

    await saisir(tester, 'Nom commun (français)', 'Basilic pourpre');
    await saisir(tester, 'Nom scientifique', 'Ocimum basilicum');
    await saisir(tester, 'Famille botanique', 'Lamiaceae');
    await saisir(tester, 'Espacement (cm)', '25');
    await saisir(tester, 'Récolte : minimum (jours)', '40');
    await saisir(tester, 'Récolte : maximum (jours)', '70');
    await tester.tap(find.widgetWithText(FilterChip, 'Alimentaire'));
    await tester.tap(find.widgetWithText(FilterChip, 'Riche'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.sauvegarder(captureAny())).captured.single
            as FichePlantePersonnelle;
    final m = captured.contenu;
    expect(m.nomCommunFr, 'Basilic pourpre');
    expect(m.nomScientifique, 'Ocimum basilicum');
    expect(m.familleBotanique, 'Lamiaceae');
    expect(m.idFiche, 'perso_basilic_pourpre');
    expect(m.categorie, CategoriePlante.legume); // default
    expect(m.usages, contains(UsagePlante.alimentaire));
    expect(m.qualitesSol, contains(QualiteSol.riche));
    expect(m.espacementCm, 25);
    expect(m.dureeAvantRecolteJoursMin, 40);
    expect(m.dureeAvantRecolteJoursMax, 70);
  });

  testWidgets('blocks the save and surfaces errors when required fields are empty',
      (tester) async {
    await monter(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    // Required text fields and the two required multi-selects all complain.
    expect(find.text('Ce champ est obligatoire.'), findsWidgets);
    expect(find.text('Choisissez au moins un usage.'), findsOneWidget);
    expect(find.text('Choisissez au moins une qualité de sol.'), findsOneWidget);
    verifyNever(() => repo.sauvegarder(any()));
  });

  testWidgets('rejects a harvest maximum below the minimum', (tester) async {
    await monter(tester);

    await saisir(tester, 'Nom commun (français)', 'Test');
    await saisir(tester, 'Nom scientifique', 'Testus');
    await saisir(tester, 'Famille botanique', 'Testaceae');
    await saisir(tester, 'Espacement (cm)', '25');
    await saisir(tester, 'Récolte : minimum (jours)', '70');
    await saisir(tester, 'Récolte : maximum (jours)', '40');
    await tester.tap(find.widgetWithText(FilterChip, 'Alimentaire'));
    await tester.tap(find.widgetWithText(FilterChip, 'Riche'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Doit être ≥ au minimum.'), findsOneWidget);
    verifyNever(() => repo.sauvegarder(any()));
  });
}
