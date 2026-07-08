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
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_releve_meteo.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_equipement_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_cache.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/providers/ajout_plante_provider.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_zone_detail.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockEquipements extends Mock implements AbstractEquipementRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class _FakePlantation extends Fake implements Plantation {}

class _FakeLocalisation extends Fake implements Localisation {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePlantation());
    registerFallbackValue(CibleTache.plantation);
    registerFallbackValue(_FakeLocalisation());
  });

  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockFiches fiches;
  late MockTaches taches;
  late MockEquipements equipements;
  late MockMeteo meteo;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    fiches = MockFiches();
    taches = MockTaches();
    equipements = MockEquipements();
    meteo = MockMeteo();
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => taches.obtenirParCible(any(), any()))
        .thenAnswer((_) async => []);
    when(() => plantations.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
    when(() => plantations.obtenirParId(any())).thenAnswer((_) async => null);
    when(() => plantations.sauvegarder(any())).thenAnswer((_) async {});
    when(() => plantations.supprimer(any())).thenAnswer((_) async {});
    when(() => parcelles.supprimer(any())).thenAnswer((_) async {});
    when(() => equipements.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
    // Minimal forecast for the watering advice provider (conseil arrosage).
    when(() => meteo.obtenirPrevisions(any(), any(),
            joursPasses: any(named: 'joursPasses')))
        .thenAnswer((_) async => [
              PrevisionMeteo(
                date: DateTime(2026, 6, 9),
                tempMin: 14,
                tempMax: 24,
                precipitationsMm: 0,
                type: TypeReleveMeteo.prevu,
              ),
            ]);
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
    final pl = unePlantation('p-1', 'tomate');
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [pl]);
    when(() => plantations.obtenirParId('p-1')).thenAnswer((_) async => pl);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));
    when(() => parcelles.obtenirParId('z-1')).thenAnswer((_) async => Parcelle(
          id: 'z-1',
          nom: 'Carré nord',
          potagerId: 'pot-1',
          type: TypeParcelle.bacSureleve,
          surface: Surface.enMetresCarres(2),
          exposition: NiveauSoleil.pleinSoleil,
        ));
  }

  Future<void> monter(WidgetTester tester, String zoneId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          plantationRepositoryProvider.overrideWithValue(plantations),
          equipementRepositoryProvider.overrideWithValue(equipements),
          meteoServiceProvider.overrideWithValue(meteo),
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
    // Derived growth stage: sown 2026-04-01, clock 2026-06-09 (69 days) for a
    // 60-day-min crop → past the harvest window.
    expect(find.text('Récolte'), findsOneWidget);
  });

  testWidgets('shows the next pending task of a crop (tâche↔plantation link)',
      (tester) async {
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
    // Two tasks target the crop; the earliest pending one wins. A done task is
    // ignored even though it is earlier still.
    when(() => taches.obtenirParCible(CibleTache.plantation, 'p-1'))
        .thenAnswer((_) async => [
              Tache(
                id: 't-late',
                titre: 'Tuteurer',
                type: TypeTache.tuteurage,
                cible: CibleTache.plantation,
                cibleId: 'p-1',
                datePrevue: DateTime(2026, 6, 20),
              ),
              Tache(
                id: 't-next',
                titre: 'Arroser',
                type: TypeTache.arrosage,
                cible: CibleTache.plantation,
                cibleId: 'p-1',
                datePrevue: DateTime(2026, 6, 12),
              ),
            ]);

    await monter(tester, 'z-1');

    expect(find.text('Prochaine : Arroser · 12/06'), findsOneWidget);
    expect(find.textContaining('Tuteurer'), findsNothing);
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

  // ── Rotation section (expert, rotation avancée Lot 4) ─────────────────────

  FichePlante ficheRotation() => FichePlante(
        id: 'tomate',
        nomScientifique: 'Solanum lycopersicum',
        familleBotanique: 'solanaceae',
        rotationFamille: 'solanaceae',
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
        delaiRetourAnnees: 4,
      );

  // Seeds zone z-1 with a solanaceae culture grown this year, resolvable in the
  // full catalogue (which the rotation synthesis reads via obtenirToutes).
  void semerPourRotation() {
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('p-1', 'tomate')]);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => ficheRotation());
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [ficheRotation()]);
  }

  Future<void> monterAvecNiveau(
    WidgetTester tester,
    NiveauExperience niveau,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          plantationRepositoryProvider.overrideWithValue(plantations),
          equipementRepositoryProvider.overrideWithValue(equipements),
          meteoServiceProvider.overrideWithValue(meteo),
          tacheRepositoryProvider.overrideWithValue(taches),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          familleBotaniqueCacheProvider.overrideWith((ref) async =>
              FamilleBotaniqueCache([
                FamilleBotanique(
                  id: 'solanaceae',
                  nomScientifique: 'Solanaceae',
                  categories: const {CategoriePlante.legume},
                  nomsLocalises: const {'fr': 'Solanacées'},
                ),
              ])),
          accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranZoneDetail(zoneId: 'z-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('expert: the rotation section reads out history and blocks',
      (tester) async {
    semerPourRotation();
    await monterAvecNiveau(tester, NiveauExperience.expert);

    expect(find.text('Rotation'), findsOneWidget);
    // Grown here recently: family name + example plant + year (2026).
    expect(find.textContaining('Solanacées'), findsWidgets);
    expect(find.textContaining('Tomate'), findsWidgets);
    // Blocked until 2026 + 4 = 2030.
    expect(find.textContaining('2030'), findsOneWidget);
  });

  testWidgets('below expert: the rotation section is hidden', (tester) async {
    semerPourRotation();
    await monterAvecNiveau(tester, NiveauExperience.intermediaire);

    expect(find.text('Rotation'), findsNothing);
  });
}
