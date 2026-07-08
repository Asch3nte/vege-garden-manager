// Widget tests for lot 2 of the personal-sheet feature: the "Perso" badge that
// tags a user-authored sheet inside the catalogue, and the detail sheet's
// editor actions (duplicate a built-in sheet / edit a personal one), gated by
// the expert tier.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_cache.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_catalogue.dart';
import 'package:pot_a_gerer/presentation/widgets/badge_perso.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockFichesPerso extends Mock
    implements AbstractFichePlantePersonnelleRepository {}

void main() {
  late MockFiches fiches;
  late MockPotagers potagers;
  late MockFichesPerso fichesPerso;

  FichePlante fiche(String id, String nomFr, CategoriePlante cat) => FichePlante(
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
      );

  setUp(() {
    fiches = MockFiches();
    potagers = MockPotagers();
    fichesPerso = MockFichesPerso();
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    when(() => fiches.obtenirToutes()).thenAnswer(
      (_) async => [
        fiche('tomate', 'Tomate', CategoriePlante.legume),
        // A merged personal sheet (its id is in the personal-ids set below).
        fiche('perso_basilic', 'Basilic de mémé', CategoriePlante.aromatique),
      ],
    );
  });

  Future<void> monter(
    WidgetTester tester, {
    NiveauExperience niveau = NiveauExperience.expert,
    Set<String> idsPerso = const {'perso_basilic'},
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          fichePlantePersonnelleRepositoryProvider
              .overrideWithValue(fichesPerso),
          idsFichesPersonnellesProvider.overrideWith((ref) async => idsPerso),
          familleBotaniqueCacheProvider
              .overrideWith((ref) async => FamilleBotaniqueCache(const [])),
          bioagresseurCacheProvider
              .overrideWith((ref) async => BioagresseurCache(const [])),
          potagerRepositoryProvider.overrideWithValue(potagers),
          accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
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

  testWidgets('tags a merged personal sheet with the Perso badge, not a built-in',
      (tester) async {
    await monter(tester);

    // One badge, on the personal sheet's card.
    expect(find.byType(BadgePerso), findsOneWidget);
    final badge = find.byType(BadgePerso);
    final carteBasilic = find.ancestor(
      of: find.text('Basilic de mémé'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: carteBasilic, matching: badge),
      findsOneWidget,
    );
  });

  testWidgets('offers "duplicate" on a built-in sheet detail (expert)',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Dupliquer en fiche perso'), findsOneWidget);
    expect(find.text('Modifier cette fiche'), findsNothing);
  });

  testWidgets('offers "edit" on a personal sheet detail (expert)',
      (tester) async {
    await monter(tester);

    await tester.tap(find.text('Basilic de mémé'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Modifier cette fiche'), findsOneWidget);
    expect(find.text('Dupliquer en fiche perso'), findsNothing);
  });

  testWidgets('hides editor actions below expert but keeps the badge',
      (tester) async {
    await monter(tester, niveau: NiveauExperience.intermediaire);

    // Badge still tags the personal sheet for everyone.
    expect(find.byType(BadgePerso), findsOneWidget);

    // No editor menu on the detail sheet for a non-expert.
    await tester.tap(find.text('Tomate'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}
