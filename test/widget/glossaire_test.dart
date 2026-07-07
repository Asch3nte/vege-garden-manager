// Widget tests for the « Aide & lexique » glossary (ADR-0017, Lot 2):
// the panel (chapters, search, novice entry), the chapter list, the term page
// (definition, astuce, conseils, derived blocks, clickable chips and wiki
// links), and the global-history guarantee — system back replays term pages
// in the exact order the user opened them.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pot_a_gerer/app/router.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_bioagresseur.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_cache.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/main.dart';
import 'package:pot_a_gerer/presentation/glossaire/ecran_chapitre_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/glossaire_providers.dart';
import 'package:pot_a_gerer/presentation/glossaire/page_terme_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/panneau_aide.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_catalogue.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/presentation/glossaire/terme_glossaire.dart';
import 'package:pot_a_gerer/presentation/widgets/champ_deroulant_decrit.dart';
import 'package:pot_a_gerer/presentation/widgets/libelles_enums.dart';

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

class _MockParcelles extends Mock implements AbstractParcelleRepository {}

class _MockTaches extends Mock implements AbstractTacheRepository {}

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _MockFiches extends Mock implements AbstractFichePlanteRepository {}

/// Reference fixtures: one family sharing one disease, so the family page has
/// a clickable chip towards the disease page and vice versa (inverse links).
final _familles = [
  FamilleBotanique(
    id: 'solanaceae',
    nomScientifique: 'Solanaceae',
    categories: {CategoriePlante.legume},
    nomsLocalises: {'fr': 'Solanacées'},
    descriptionsLocalisees: {'fr': 'La famille des tomates et aubergines.'},
    maladiesCommunes: {'mildiou'},
  ),
];

final _bioagresseurs = [
  Bioagresseur(
    id: 'mildiou',
    type: TypeBioagresseur.maladie,
    nomsLocalises: {'fr': 'Mildiou'},
    descriptionsLocalisees: {'fr': 'Champignon favorisé par l’humidité.'},
  ),
];

/// Fires the tap recognizer of the wiki-link span displaying [texte].
void _taperLien(WidgetTester tester, String texte) {
  TapGestureRecognizer? recognizer;
  for (final widget in tester.widgetList<Text>(find.byType(Text))) {
    widget.textSpan?.visitChildren((span) {
      if (span is TextSpan &&
          span.text == texte &&
          span.recognizer is TapGestureRecognizer) {
        recognizer = span.recognizer as TapGestureRecognizer;
        return false;
      }
      return true;
    });
  }
  expect(recognizer, isNotNull, reason: 'lien « $texte » introuvable');
  recognizer!.onTap!();
}

void main() {
  // --- Standalone harness: the /plus/aide subtree with fixture data. --------
  Future<void> monter(WidgetTester tester, {String? initialLocation}) async {
    final router = GoRouter(
      initialLocation: initialLocation ?? RoutesApp.plusAide,
      routes: [
        GoRoute(
          path: RoutesApp.plusAide,
          builder: (context, state) => const PanneauAide(),
          routes: [
            GoRoute(
              path: RoutesApp.aideChapitreSegment,
              builder: (context, state) => EcranChapitreGlossaire(
                  nomChapitre: state.pathParameters['nom']!),
            ),
            GoRoute(
              path: RoutesApp.aideTermeSegment,
              builder: (context, state) =>
                  PageTermeGlossaire(idTerme: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glossaireDonneesProvider.overrideWith((ref) async =>
              (familles: _familles, bioagresseurs: _bioagresseurs)),
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

  testWidgets('the cover lists the nine chapters with entry counts and the'
      ' novice entry', (tester) async {
    await monter(tester);

    expect(find.text('Par où commencer ?'), findsOneWidget);
    expect(find.text('Familles botaniques'), findsOneWidget);
    expect(find.text('Santé du jardin'), findsOneWidget);
    expect(find.text('Outils & équipements'), findsOneWidget);
    // Familles botaniques = famille.solanaceae + 2 seed notions ;
    // Santé du jardin = bio.mildiou + 2 notions (Lot 4).
    expect(find.text('3 entrées'), findsNWidgets(2));
    // Outils & équipements = 13 pages d'outils + états d'un équipement (Lot 4).
    expect(find.text('14 entrées'), findsOneWidget);
  });

  testWidgets(
      'enum-value descriptions render wiki links — never a raw [[…]] (Lot 4)',
      (tester) async {
    await monter(tester,
        initialLocation: '${RoutesApp.plusAide}/terme/notion.usage-plante');

    // No raw wiki syntax anywhere on the page.
    expect(find.textContaining('[[', findRichText: true), findsNothing);

    // The link embedded in the « Répulsive » value description is tappable
    // and navigates to the mechanism page.
    _taperLien(tester, 'répulsion');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Éloigne un ravageur'), findsOneWidget);
  });

  testWidgets(
      'a form field help icon (« ? ») opens the concept glossary page (#4bis)',
      (tester) async {
    // Minimal form harness: one described dropdown with a glossary help id,
    // plus the aide routes so the navigation lands somewhere.
    final router = GoRouter(
      initialLocation: '/form',
      routes: [
        GoRoute(
          path: '/form',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => ChampDeroulantDecrit<TypeClimat>(
                value: TypeClimat.oceanique,
                options: TypeClimat.values,
                libelle: AppLocalizations.of(context)!.climat,
                description: AppLocalizations.of(context)!.climatDescription,
                labelText: 'Climat',
                idAideGlossaire: TermeGlossaire.idNotion('type-climat'),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
        GoRoute(
          path: RoutesApp.plusAide,
          builder: (context, state) => const PanneauAide(),
          routes: [
            GoRoute(
              path: RoutesApp.aideTermeSegment,
              builder: (context, state) =>
                  PageTermeGlossaire(idTerme: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glossaireDonneesProvider.overrideWith((ref) async =>
              (familles: _familles, bioagresseurs: _bioagresseurs)),
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

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Types de climat'), findsOneWidget);
  });

  testWidgets('search finds a term (accents ignored) and opens its page',
      (tester) async {
    await monter(tester);

    await tester.enterText(find.byType(TextField), 'MILDIOU');
    await tester.pumpAndSettle();
    expect(find.text('Mildiou'), findsOneWidget);

    await tester.tap(find.text('Mildiou'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mildiou'), findsOneWidget);
    expect(find.textContaining('Champignon favorisé'), findsOneWidget);
  });

  testWidgets('an empty search shows the empty state', (tester) async {
    await monter(tester);

    await tester.enterText(find.byType(TextField), 'courgette');
    await tester.pumpAndSettle();
    expect(find.text('Aucun terme ne correspond à cette recherche.'),
        findsOneWidget);
  });

  testWidgets('a chapter opens on its term list', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Santé du jardin'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Santé du jardin'), findsOneWidget);
    expect(find.text('Mildiou'), findsOneWidget);
  });

  testWidgets('the term page renders definition, astuce, conseils and rendered'
      ' wiki links', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Par où commencer ?'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Par où commencer ?'), findsOneWidget);
    expect(find.textContaining('Bienvenue dans le lexique'), findsOneWidget);
    expect(find.text('Astuce'), findsOneWidget);
    expect(find.text('Conseils'), findsOneWidget);

    // The wiki link displays its label and navigates to the target page.
    _taperLien(tester, 'rotation des cultures');
    await tester.pumpAndSettle();
    expect(
        find.widgetWithText(AppBar, 'Rotation des cultures'), findsOneWidget);
  });

  testWidgets('family and disease pages cross-link through clickable chips',
      (tester) async {
    await monter(tester);

    // Cover → chapter → family page.
    await tester.tap(find.text('Familles botaniques'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solanacées'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Solanacées'), findsOneWidget);
    expect(find.text('Solanaceae'), findsOneWidget); // scientific name
    expect(find.text('Maladies courantes'), findsOneWidget);

    // Disease chip → disease page, which links back the family (inverse).
    await tester.tap(find.widgetWithText(ActionChip, 'Mildiou'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mildiou'), findsOneWidget);
    expect(find.text('Familles concernées'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Solanacées'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Solanacées'), findsOneWidget);
  });

  testWidgets('an unknown term id renders the not-found body', (tester) async {
    await monter(tester);

    await tester.enterText(find.byType(TextField), 'mildiou');
    await tester.pumpAndSettle();
    // Navigate directly to a bogus id through the router.
    final context = tester.element(find.byType(PanneauAide));
    context.go(RoutesApp.aideTerme('notion.inexistant'));
    await tester.pumpAndSettle();
    expect(find.text("Ce terme n'existe pas (ou plus) dans le lexique."),
        findsOneWidget);
  });

  // --- Full-app harness: the global back history across term pages. ---------
  Future<void> monterApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final potagers = _MockPotagers();
    final parcelles = _MockParcelles();
    final taches = _MockTaches();
    final preferences = _MockPreferences();
    final fiches = _MockFiches();
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => preferences.charger()).thenAnswer(
        (_) async => PreferencesUtilisateur(onboardingTermine: true));
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          tacheRepositoryProvider.overrideWithValue(taches),
          preferencesRepositoryProvider.overrideWithValue(preferences),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          glossaireDonneesProvider.overrideWith((ref) async =>
              (familles: _familles, bioagresseurs: _bioagresseurs)),
        ],
        child: const PotAGererApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('system back replays glossary pages in opening order (D3)',
      (tester) async {
    await monterApp(tester);

    // Accueil → Plus → Aide & lexique → « Par où commencer ? » →
    // [[rotation des cultures]] → [[famille de plantes]].
    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aide & lexique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Par où commencer ?'));
    await tester.pumpAndSettle();
    _taperLien(tester, 'rotation des cultures');
    await tester.pumpAndSettle();
    expect(
        find.widgetWithText(AppBar, 'Rotation des cultures'), findsOneWidget);
    _taperLien(tester, 'famille de plantes');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Famille botanique'), findsOneWidget);

    // Back replays the exact opening order: rotation → par-où-commencer →
    // aide cover → plus root → accueil.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
        find.widgetWithText(AppBar, 'Rotation des cultures'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Par où commencer ?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Aide & lexique'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Préférences générales'), findsOneWidget);
  });

  // --- Lot 3: clickable terms from an app surface (the plant sheet). --------
  Future<void> monterCatalogue(WidgetTester tester) async {
    final fiches = _MockFiches();
    final potagers = _MockPotagers();
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => [
          FichePlante(
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
            periodes: const {},
          ),
        ]);

    final router = GoRouter(
      initialLocation: '/catalogue',
      routes: [
        GoRoute(
          path: '/catalogue',
          builder: (context, state) => const EcranCatalogue(),
        ),
        GoRoute(
          path: RoutesApp.plusAide,
          builder: (context, state) => const PanneauAide(),
          routes: [
            GoRoute(
              path: RoutesApp.aideTermeSegment,
              builder: (context, state) =>
                  PageTermeGlossaire(idTerme: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          potagerRepositoryProvider.overrideWithValue(potagers),
          accesNiveauProvider
              .overrideWithValue(AccesNiveau(NiveauExperience.debutant)),
          // The family education section reads the caches directly.
          familleBotaniqueCacheProvider
              .overrideWith((ref) async => FamilleBotaniqueCache(_familles)),
          bioagresseurCacheProvider
              .overrideWith((ref) async => BioagresseurCache(_bioagresseurs)),
          glossaireDonneesProvider.overrideWith((ref) async =>
              (familles: _familles, bioagresseurs: _bioagresseurs)),
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

  testWidgets(
      'the plant sheet family name opens its glossary page; back returns to'
      ' the sheet (Lot 3, révisé #4bis)', (tester) async {
    await monterCatalogue(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Solanacées'), 200,
        scrollable: find.byType(Scrollable).last);
    // One extra notch: the sheet's sticky CTA footer overlays the last ~150px,
    // scrollUntilVisible stops as soon as the text enters the viewport.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -150));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Solanacées'));
    await tester.pumpAndSettle();

    // The term page is pushed ABOVE the sheet (which stays alive underneath).
    expect(find.widgetWithText(AppBar, 'Solanacées'), findsOneWidget);
    expect(find.textContaining('La famille des tomates'), findsOneWidget);

    // Back returns to the sheet exactly where the user left it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Solanacées'), findsOneWidget);
  });

  testWidgets(
      'a plant sheet fact label (Exposition) opens its concept page; back'
      ' returns to the sheet (#4bis)', (tester) async {
    await monterCatalogue(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exposition'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Exposition au soleil'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets(
      'the plant sheet disease chip opens the bioaggressor glossary page'
      ' (Lot 3)', (tester) async {
    await monterCatalogue(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.widgetWithText(ActionChip, 'Mildiou'), 200,
        scrollable: find.byType(Scrollable).last);
    // One extra notch past the sheet's sticky CTA footer (see above).
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -150));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Mildiou'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Mildiou'), findsOneWidget);
    expect(find.text('Familles concernées'), findsOneWidget);

    // Term → term from the pushed page: the family chip pushes again; two
    // backs replay the pages in opening order, then the sheet reappears.
    await tester.tap(find.widgetWithText(ActionChip, 'Solanacées'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Solanacées'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mildiou'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
