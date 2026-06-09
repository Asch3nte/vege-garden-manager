// Widget tests for the Catalogue screen (Fiches view).
//
// Overrides the catalogue repository with a small in-memory set and checks
// rendering, search, category filtering, the empty state and the detail sheet.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_catalogue.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

void main() {
  late MockFiches fiches;

  FichePlante fiche(
    String id,
    String nomFr,
    CategoriePlante cat, {
    Set<String> bons = const {},
  }) =>
      FichePlante(
        id: id,
        nomScientifique: '$id sp',
        familleBotanique: 'Test',
        categorie: cat,
        usages: const {UsagePlante.alimentaire},
        nomsLocalises: {'fr': nomFr},
        besoins: BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 7,
        ),
        espacementCm: 40,
        dureeAvantRecolteJoursMin: 60,
        dureeAvantRecolteJoursMax: 80,
        periodes: const {},
        associationsBenefiques: bons,
      );

  setUp(() {
    fiches = MockFiches();
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume, bons: {'basilic'}),
        fiche('basilic', 'Basilic', CategoriePlante.aromatique),
        fiche('fraise', 'Fraise', CategoriePlante.petitFruit),
      ],
    );
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranCatalogue(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists all plants ordered by name', (tester) async {
    await monter(tester);

    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Basilic'), findsOneWidget);
    expect(find.text('Fraise'), findsOneWidget);
  });

  testWidgets('search narrows the list', (tester) async {
    await monter(tester);

    await tester.enterText(find.byType(TextField), 'tom');
    await tester.pumpAndSettle();

    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Basilic'), findsNothing);
  });

  testWidgets('category chip filters the list', (tester) async {
    await monter(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Aromatiques'));
    await tester.pumpAndSettle();

    expect(find.text('Basilic'), findsOneWidget);
    expect(find.text('Tomate'), findsNothing);
  });

  testWidgets('no match shows the empty state', (tester) async {
    await monter(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Aucune plante ne correspond.'), findsOneWidget);
  });

  testWidgets('tapping a card opens the detail with companions',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    // The detail sheet shows the associations section and the good companion.
    expect(find.text('Associations'), findsOneWidget);
    expect(find.text('Bons compagnons'), findsOneWidget);
    // "Basilic" now also appears as a companion chip inside the sheet.
    expect(find.text('Basilic'), findsWidgets);
  });
}
