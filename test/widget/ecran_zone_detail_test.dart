// Widget tests for the zone-detail screen.
//
// Overrides the repositories so the Potager view-model resolves a known zone,
// then checks the detail renders its real facts/crops and the not-found state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/router.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/providers/ajout_plante_provider.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_zone_detail.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class _FakePlantation extends Fake implements Plantation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePlantation()));

  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockFiches fiches;
  late MockTaches taches;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    fiches = MockFiches();
    taches = MockTaches();
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => plantations.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
    when(() => plantations.sauvegarder(any())).thenAnswer((_) async {});
    when(() => plantations.supprimer(any())).thenAnswer((_) async {});
    when(() => parcelles.supprimer(any())).thenAnswer((_) async {});
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      ),
    );
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        Parcelle(
          id: 'z-1',
          nom: 'Carré nord',
          potagerId: 'pot-1',
          type: TypeParcelle.bacSureleve,
          surface: Surface.enMetresCarres(2),
          exposition: NiveauSoleil.pleinSoleil,
        ),
      ],
    );
  });

  FichePlante uneFiche(String id, String nomFr) => FichePlante(
        id: id,
        nomScientifique: '$id sp',
        familleBotanique: 'Test',
        categorie: CategoriePlante.legume,
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

  Plantation unePlantation(String id, String planteId) => Plantation(
        id: id,
        planteId: planteId,
        parcelleId: 'z-1',
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 3,
      );

  // Seeds zone z-1 with one active crop (Tomate).
  void semerUneCulture() {
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('p-1', 'tomate')]);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));
  }

  Future<void> monter(WidgetTester tester, String zoneId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          plantationRepositoryProvider.overrideWithValue(plantations),
          tacheRepositoryProvider.overrideWithValue(taches),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EcranZoneDetail(zoneId: zoneId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the zone facts and its crops', (tester) async {
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [
              Plantation(
                id: 'p-1',
                planteId: 'tomate',
                parcelleId: 'z-1',
                dateMiseEnPlace: DateTime(2026, 4, 1),
                methode: MethodeMiseEnPlace.semisDirect,
                surfaceOccupee: Surface.enMetresCarres(0.5),
                nombrePieds: 3,
              ),
            ]);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));

    await monter(tester, 'z-1');

    expect(find.widgetWithText(AppBar, 'Carré nord'), findsOneWidget);
    expect(find.text('Bac surélevé'), findsOneWidget);
    expect(find.text('2 m²'), findsOneWidget);
    expect(find.text('Plein soleil'), findsOneWidget);
    expect(find.text('Cultures'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
  });

  testWidgets('shows a not-found message for an unknown zone', (tester) async {
    await monter(tester, 'absent');

    expect(find.text('Zone introuvable.'), findsOneWidget);
  });

  testWidgets('"Ajouter une plante" targets the zone and opens the catalogue',
      (tester) async {
    final router = GoRouter(
      initialLocation: RoutesApp.zoneDetail('z-1'),
      routes: [
        GoRoute(
          path: RoutesApp.potager,
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: RoutesApp.zoneDetailSegment,
              builder: (context, state) =>
                  EcranZoneDetail(zoneId: state.pathParameters['id']!),
            ),
          ],
        ),
        // Catalogue stand-in echoing the pending target zone name.
        GoRoute(
          path: RoutesApp.catalogue,
          builder: (context, state) => Consumer(
            builder: (context, ref, _) {
              final cible = ref.watch(ajoutPlanteProvider);
              return Scaffold(body: Center(child: Text('cible:${cible?.zoneNom}')));
            },
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          plantationRepositoryProvider.overrideWithValue(plantations),
          tacheRepositoryProvider.overrideWithValue(taches),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          horlogeProvider.overrideWithValue(() => maintenant),
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

    await tester.tap(find.text('Ajouter une plante'));
    await tester.pumpAndSettle();

    // Navigated to the catalogue, which now sees "Carré nord" as the target.
    expect(find.text('cible:Carré nord'), findsOneWidget);
  });

  testWidgets('pulling out a crop marks it as arrachee', (tester) async {
    semerUneCulture();
    await monter(tester, 'z-1');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arracher'));
    await tester.pumpAndSettle();

    final p = verify(() => plantations.sauvegarder(captureAny()))
        .captured
        .single as Plantation;
    expect(p.id, 'p-1');
    expect(p.statut, StatutPlantation.arrachee);
  });

  testWidgets('removing a crop deletes it after confirmation', (tester) async {
    semerUneCulture();
    await monter(tester, 'z-1');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer')); // menu item
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette plante ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer')); // confirm
    await tester.pumpAndSettle();

    verify(() => plantations.supprimer('p-1')).called(1);
  });

  testWidgets('deleting the zone confirms then soft-deletes it and returns',
      (tester) async {
    final router = GoRouter(
      initialLocation: RoutesApp.zoneDetail('z-1'),
      routes: [
        GoRoute(
          path: RoutesApp.potager,
          builder: (context, state) => const Scaffold(body: Text('PLAN')),
          routes: [
            GoRoute(
              path: RoutesApp.zoneDetailSegment,
              builder: (context, state) =>
                  EcranZoneDetail(zoneId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          plantationRepositoryProvider.overrideWithValue(plantations),
          tacheRepositoryProvider.overrideWithValue(taches),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          horlogeProvider.overrideWithValue(() => maintenant),
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

    await tester.tap(find.byTooltip('Supprimer la zone'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette zone ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    verify(() => parcelles.supprimer('z-1')).called(1);
    expect(find.text('PLAN'), findsOneWidget);
  });
}
