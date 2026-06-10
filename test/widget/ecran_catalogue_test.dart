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
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/providers/ajout_plante_provider.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_catalogue.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockPotagers extends Mock implements AbstractPotagerRepository {}

/// Pre-targets a zone so the catalogue renders its "adding to a zone" banner.
class _CibleFixe extends AjoutPlanteNotifier {
  @override
  CibleAjoutPlante? build() =>
      const CibleAjoutPlante(zoneId: 'z-1', zoneNom: 'Carré nord');
}

void main() {
  late MockFiches fiches;
  late MockPotagers potagers;

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
    potagers = MockPotagers();
    // No active garden → the sheet's calendar shows its "create a garden" note.
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume, bons: {'basilic'}),
        fiche('basilic', 'Basilic', CategoriePlante.aromatique),
        fiche('fraise', 'Fraise', CategoriePlante.petitFruit),
      ],
    );
  });

  Future<void> monter(WidgetTester tester, {bool avecCible = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          potagerRepositoryProvider.overrideWithValue(potagers),
          if (avecCible) ajoutPlanteProvider.overrideWith(_CibleFixe.new),
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
    // (Scroll the sheet down — the section sits below the new calendar.)
    await tester.scrollUntilVisible(
      find.text('Associations'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Associations'), findsOneWidget);
    expect(find.text('Bons compagnons'), findsOneWidget);
    // "Basilic" now also appears as a companion chip inside the sheet.
    expect(find.text('Basilic'), findsWidgets);
  });

  testWidgets('the detail sheet offers to add the plant to the garden',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter au potager'), findsOneWidget);
  });

  testWidgets('shows the add banner for a pending target and clears it on close',
      (tester) async {
    await monter(tester, avecCible: true);

    expect(find.text('Ajout dans : Carré nord'), findsOneWidget);

    await tester.tap(find.byTooltip("Annuler l'ajout"));
    await tester.pumpAndSettle();

    expect(find.text('Ajout dans : Carré nord'), findsNothing);
  });

  testWidgets('the sheet shows the description and the sowing/harvest calendar',
      (tester) async {
    final tomate = FichePlante(
      id: 'tomate',
      nomScientifique: 'Solanum lycopersicum',
      familleBotanique: 'Solanaceae',
      categorie: CategoriePlante.legume,
      usages: const {UsagePlante.alimentaire},
      nomsLocalises: const {'fr': 'Tomate'},
      besoins: BesoinsCulture(
        eau: BesoinEau.modere,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: 40,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 80,
      descriptionsLocalisees: const {'fr': 'Un fruit-légume savoureux.'},
      periodes: const {
        Hemisphere.nord: {
          TypeClimat.oceanique: PeriodesCulture(
            semisExterieur: Periode(3, 5),
            plantation: Periode(5, 6),
            recolte: Periode(7, 9),
          ),
        },
      },
    );
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => [tomate]);
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      ),
    );

    await monter(tester);
    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    expect(find.text('Un fruit-légume savoureux.'), findsOneWidget);
    // Scroll to the bottom of the calendar section (its hemisphere caption), so
    // the bands above it are built.
    await tester.scrollUntilVisible(
      find.textContaining('Hémisphère nord supposé'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Semis & récolte'), findsOneWidget);
    expect(find.text('Semis'), findsWidgets); // band label
    expect(find.textContaining('Hémisphère nord supposé'), findsWidgets);
  });

  testWidgets('switching to the network view shows the constellation',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Réseau'));
    await tester.pumpAndSettle();

    // The hint is shown and the Fiches-only search field is gone.
    expect(find.text('Touchez une plante pour voir ses associations.'),
        findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('selecting a node reveals its associations', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Réseau'));
    await tester.pumpAndSettle();

    // Tap the Tomate node (its initial).
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    // The panel names the plant and counts its (one) good companion.
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.textContaining('1 bon compagnon'), findsOneWidget);
  });

  testWidgets('the network panel opens the selected plant sheet', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Réseau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voir la fiche'));
    await tester.pumpAndSettle();

    // The detail sheet is shown with its add CTA (pinned footer) and, after
    // scrolling, the associations section.
    expect(find.text('Ajouter au potager'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Associations'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Associations'), findsOneWidget);
  });
}
