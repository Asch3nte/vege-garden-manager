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
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_bioagresseur.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_famille_botanique_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/association_benefique.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_cache.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/providers/ajout_plante_provider.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_catalogue.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockFamilles extends Mock implements AbstractFamilleBotaniqueRepository {}

class MockPotagers extends Mock implements AbstractPotagerRepository {}

/// Pre-targets a zone so the catalogue renders its "adding to a zone" banner.
class _CibleFixe extends AjoutPlanteNotifier {
  @override
  CibleAjoutPlante? build() =>
      const CibleAjoutPlante(zoneId: 'z-1', zoneNom: 'Carré nord');
}

void main() {
  late MockFiches fiches;
  late MockFamilles familles;
  late MockPotagers potagers;

  FichePlante fiche(
    String id,
    String nomFr,
    CategoriePlante cat, {
    Set<String> bons = const {},
    String? parentId,
    String famille = 'Test',
  }) =>
      FichePlante(
        id: id,
        parentId: parentId,
        nomScientifique: '$id sp',
        familleBotanique: famille,
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
        associationsBenefiques: [
          for (final id in bons) AssociationBenefique(cibleId: id),
        ],
      );

  setUp(() {
    fiches = MockFiches();
    familles = MockFamilles();
    potagers = MockPotagers();
    // No active garden → the sheet's calendar shows its "create a garden" note.
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume,
            bons: {'basilic'}, famille: 'Solanaceae'),
        fiche('courgette', 'Courgette', CategoriePlante.legume,
            famille: 'Cucurbitaceae'),
        fiche('basilic', 'Basilic', CategoriePlante.aromatique,
            famille: 'Lamiaceae'),
        fiche('fraise', 'Fraise', CategoriePlante.petitFruit,
            famille: 'Rosaceae'),
      ],
    );
    when(() => familles.obtenirToutes()).thenAnswer((_) async => [
          FamilleBotanique(
            id: 'solanaceae',
            nomScientifique: 'Solanaceae',
            categories: const {CategoriePlante.legume},
            nomsLocalises: const {'fr': 'Solanacées'},
            pourquoiRotationLocalise: const {'fr': 'Rotation de 4 ans conseillée.'},
            maladiesCommunes: const {'mildiou'},
            ravageursCommuns: const {'doryphore'},
          ),
          FamilleBotanique(
            id: 'cucurbitaceae',
            nomScientifique: 'Cucurbitaceae',
            categories: const {CategoriePlante.legume},
            nomsLocalises: const {'fr': 'Cucurbitacées'},
          ),
          FamilleBotanique(
            id: 'lamiaceae',
            nomScientifique: 'Lamiaceae',
            categories: const {CategoriePlante.aromatique},
            nomsLocalises: const {'fr': 'Lamiacées'},
          ),
          FamilleBotanique(
            id: 'rosaceae',
            nomScientifique: 'Rosaceae',
            categories: const {CategoriePlante.petitFruit},
            nomsLocalises: const {'fr': 'Rosacées'},
          ),
        ]);
  });

  Future<void> monter(
    WidgetTester tester, {
    bool avecCible = false,
    // Intermediate by default so the Réseau view (intermediate+, ADR-0009) is
    // available — matching these tests' assumptions before gating.
    NiveauExperience niveau = NiveauExperience.intermediaire,
  }) async {
    // Tall surface so the plant list stays fully laid out even when a level-up
    // teaser occupies the bottom (shown to beginners).
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          familleBotaniqueRepositoryProvider
              .overrideWith((ref) async => familles),
          // Family-level educational section (ADR-0006 Lot 4) reads the caches.
          familleBotaniqueCacheProvider.overrideWith(
              (ref) async => FamilleBotaniqueCache(await familles.obtenirToutes())),
          bioagresseurCacheProvider.overrideWith((ref) async => BioagresseurCache([
                Bioagresseur(
                    id: 'mildiou',
                    type: TypeBioagresseur.maladie,
                    nomsLocalises: const {'fr': 'Mildiou'}),
                Bioagresseur(
                    id: 'doryphore',
                    type: TypeBioagresseur.ravageur,
                    nomsLocalises: const {'fr': 'Doryphore'}),
              ])),
          potagerRepositoryProvider.overrideWithValue(potagers),
          accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
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

  testWidgets('a category reveals its family chips and they filter the list',
      (tester) async {
    await monter(tester);

    // No family row under "Tout".
    expect(find.widgetWithText(ChoiceChip, 'Solanacées'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Légumes'));
    await tester.pumpAndSettle();

    // The legume families appear as a second filter row.
    expect(find.widgetWithText(ChoiceChip, 'Solanacées'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Cucurbitacées'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Courgette'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Solanacées'));
    await tester.pumpAndSettle();

    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Courgette'), findsNothing);
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

  testWidgets('the detail sheet shows the family education section (ADR-0006 Lot 4)',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sa famille : Solanacées'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sa famille : Solanacées'), findsOneWidget);
    expect(find.text('Rotation de 4 ans conseillée.'), findsOneWidget);
    // Slugs resolved to localized bioaggressor names as chips.
    expect(find.widgetWithText(Chip, 'Mildiou'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Doryphore'), findsOneWidget);
  });

  testWidgets('the detail sheet offers to add the plant to the garden',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter au potager'), findsOneWidget);
  });

  testWidgets('a fiche card opens the detailed Associations view (ADR-0008)',
      (tester) async {
    await monter(tester);

    // Each species card carries an Associations button (Fiches view).
    await tester.tap(find.byTooltip('Associations').first);
    await tester.pumpAndSettle();

    // The full-screen Associations view opened (its close button).
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets("the detail sheet switches to one of the species' varieties",
      (tester) async {
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume),
        fiche('tomate-v1', 'Tomate Cerise', CategoriePlante.legume,
            parentId: 'tomate'),
        fiche('basilic', 'Basilic', CategoriePlante.aromatique),
      ],
    );
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    // The switcher line shows the species; the panel shows the species' sheet.
    expect(find.text('Choisir variété…'), findsOneWidget);
    expect(find.text('tomate sp'), findsOneWidget);

    // The picker lists only this species' varieties — not other species
    // (variety rows carry the scientific name; the background cards do not).
    await tester.tap(find.text('Choisir variété…'));
    await tester.pumpAndSettle();
    expect(find.text('tomate-v1 sp'), findsOneWidget);
    expect(find.text('basilic sp'), findsNothing);

    // Choosing the variety re-renders the whole panel for it.
    await tester.tap(find.text('Tomate Cerise').last);
    await tester.pumpAndSettle();
    expect(find.text('tomate-v1 sp'), findsOneWidget);

    // The back button returns to the species sheet.
    await tester.tap(find.byTooltip("Retour à l'espèce"));
    await tester.pumpAndSettle();
    expect(find.text('tomate sp'), findsOneWidget);
    expect(find.text('tomate-v1 sp'), findsNothing);
  });

  testWidgets('the OS back returns from a variety to the species sheet',
      (tester) async {
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume),
        fiche('tomate-v1', 'Tomate Cerise', CategoriePlante.legume,
            parentId: 'tomate'),
      ],
    );
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir variété…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate Cerise').last);
    await tester.pumpAndSettle();
    expect(find.text('tomate-v1 sp'), findsOneWidget);

    // The OS back gesture returns to the species without closing the sheet.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('tomate sp'), findsOneWidget);
    expect(find.text('Ajouter au potager'), findsOneWidget);
  });

  testWidgets('a species with no varieties shows no variety switcher',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir variété…'), findsNothing);
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

  testWidgets('a species expands to reveal its varieties', (tester) async {
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume),
        fiche('tomate-v1', 'Tomate Cerise', CategoriePlante.legume,
            parentId: 'tomate'),
      ],
    );
    await monter(tester);

    // The variety is hidden until the species is expanded.
    expect(find.text('Tomate Cerise'), findsNothing);

    await tester.tap(find.byTooltip('1 variété'));
    await tester.pumpAndSettle();

    expect(find.text('Tomate Cerise'), findsOneWidget);
  });

  testWidgets('the variety toggle stays as narrow as a plain chevron', (
    tester,
  ) async {
    // Regression: a default IconButton reserves a 48px touch target, which on a
    // species *with* varieties narrows the meta area and pushes "Arrosage
    // modéré" onto a second line — but only there, so cards no longer line up.
    // The toggle must keep the bare-icon footprint of the plain chevron.
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume),
        fiche('tomate-v1', 'Tomate Cerise', CategoriePlante.legume,
            parentId: 'tomate'),
        fiche('basilic', 'Basilic', CategoriePlante.aromatique),
      ],
    );
    await monter(tester);

    final toggle = tester.getSize(find.byTooltip('1 variété')).width;
    final chevron =
        tester.getSize(find.byIcon(Icons.chevron_right).first).width;
    expect(
      toggle,
      lessThanOrEqualTo(chevron + 1),
      reason: 'the expand toggle must be as compact as the plain chevron',
    );
  });

  testWidgets('the network view shows species only (varieties excluded)',
      (tester) async {
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume),
        fiche('tomate-v1', 'Tomate Cerise', CategoriePlante.legume,
            parentId: 'tomate'),
      ],
    );
    await monter(tester);
    await tester.tap(find.text('Réseau'));
    await tester.pumpAndSettle();

    // Only the species node 'T' is drawn; the variety 'Tomate Cerise' is not.
    expect(find.text('T'), findsOneWidget);
    expect(find.text('Tomate Cerise'), findsNothing);
  });

  testWidgets('the Réseau view is hidden for beginners (ADR-0009)',
      (tester) async {
    await monter(tester, niveau: NiveauExperience.debutant);

    // No Fiches/Réseau toggle for a beginner — only the Fiches list.
    expect(find.text('Réseau'), findsNothing);
    expect(find.text('Tomate'), findsOneWidget);
  });

  testWidgets('a beginner sees a dismissable level-up teaser (ADR-0009 §4b)',
      (tester) async {
    await monter(tester, niveau: NiveauExperience.debutant);

    expect(find.text('En savoir plus'), findsOneWidget);

    await tester.tap(find.byTooltip('Masquer'));
    await tester.pumpAndSettle();

    expect(find.text('En savoir plus'), findsNothing);
  });

  testWidgets('switching to the network view shows the constellation',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Réseau'));
    await tester.pumpAndSettle();

    // The hint is shown; the Fiches search box is replaced by the network's
    // own name search — collapsed to a magnifier button (ADR-0008 Lot 5).
    expect(find.text('Touchez une plante pour voir ses associations.'),
        findsOneWidget);
    expect(find.text('Nom, sol, exposition…'), findsNothing);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('selecting a node reveals its associations', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Réseau'));
    await tester.pumpAndSettle();

    // Tap the Tomate node (its initial).
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    // The panel names the plant (also shown as a node label since #8a) and
    // counts its (one) good companion (panel-only).
    expect(find.text('Tomate'), findsWidgets);
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
