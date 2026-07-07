// Widget tests for the Potager plan screen (variant A: bed grid).
//
// Overrides the repositories + the catalogue so the screen renders a known set
// of zones, then checks the rendered beds, the task-today marker, the empty
// state and that tapping a bed opens the zone detail.
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
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/permission_localisation.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_geolocalisation_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_potager.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_zone_detail.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class MockGeoloc extends Mock implements AbstractGeolocalisationService {}

class _FakePotager extends Fake implements Potager {}

class _FakePrefs extends Fake implements PreferencesUtilisateur {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePotager());
    registerFallbackValue(_FakePrefs());
  });

  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockFiches fiches;
  late MockTaches taches;
  late MockPreferences preferences;
  late MockGeoloc geoloc;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    fiches = MockFiches();
    taches = MockTaches();
    preferences = MockPreferences();
    geoloc = MockGeoloc();
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
    when(() => plantations.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
    when(() => potagers.obtenirTous()).thenAnswer((_) async => []);
    when(() => potagers.supprimer(any())).thenAnswer((_) async {});
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => preferences.sauvegarder(any())).thenAnswer((_) async {});
  });

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      );

  Potager autrePotager() => Potager(
        id: 'pot-2',
        nom: 'Jardin de la grand-mère',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 2, 1),
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

  Parcelle uneParcelle(
    String id,
    String nom, {
    TypeParcelle type = TypeParcelle.bacSureleve,
  }) =>
      Parcelle(
        id: id,
        nom: nom,
        potagerId: 'pot-1',
        type: type,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      );

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

  Tache uneTacheParcelle(String parcelleId) => Tache(
        id: 't-$parcelleId',
        titre: 'Arroser',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: parcelleId,
        datePrevue: maintenant,
      );

  // Built lazily (per test) so it captures the mocks assigned in setUp.
  // [niveau] defaults to the most restrictive tier (débutant), matching the
  // real accesNiveauProvider default while preferences load.
  overrides({NiveauExperience niveau = NiveauExperience.debutant}) => [
        potagerRepositoryProvider.overrideWithValue(potagers),
        parcelleRepositoryProvider.overrideWithValue(parcelles),
        plantationRepositoryProvider.overrideWithValue(plantations),
        tacheRepositoryProvider.overrideWithValue(taches),
        fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
        preferencesRepositoryProvider.overrideWithValue(preferences),
        geolocalisationServiceProvider.overrideWithValue(geoloc),
        horlogeProvider.overrideWithValue(() => maintenant),
        accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
      ];

  // Mounts the screen alone (no inter-screen navigation needed).
  Future<void> monter(
    WidgetTester tester, {
    NiveauExperience niveau = NiveauExperience.debutant,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(niveau: niveau),
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranPotager(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Mounts the screen inside a router carrying the zone-detail sub-route, so a
  // bed tap can resolve `/potager/zone/:id`.
  Future<void> monterAvecRouteur(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: RoutesApp.potager,
      routes: [
        GoRoute(
          path: RoutesApp.potager,
          builder: (context, state) => const EcranPotager(),
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
        overrides: overrides(),
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

  testWidgets('renders a bed per zone with its crops', (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        uneParcelle('z-1', 'Carré nord'),
        uneParcelle('z-2', 'Serre', type: TypeParcelle.serre),
      ],
    );
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('p-1', 'tomate')]);
    when(() => plantations.obtenirParParcelle('z-2'))
        .thenAnswer((_) async => [unePlantation('p-2', 'aubergine')]);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));
    when(() => fiches.obtenirParId('aubergine'))
        .thenAnswer((_) async => uneFiche('aubergine', 'Aubergine'));

    await monter(tester);

    expect(find.text('Carré nord'), findsOneWidget);
    expect(find.text('Serre'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Aubergine'), findsOneWidget);
  });

  testWidgets('marks a bed with a drop when a task is due today',
      (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        uneParcelle('z-1', 'Avec tâche'),
        uneParcelle('z-2', 'Sans tâche'),
      ],
    );
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [uneTacheParcelle('z-1')]);

    await monter(tester);

    expect(find.byKey(const Key('tache-z-1')), findsOneWidget);
    expect(find.byKey(const Key('tache-z-2')), findsNothing);
  });

  testWidgets('tapping a bed opens the zone detail', (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1', 'Carré nord')]);
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('p-1', 'tomate')]);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));

    await monterAvecRouteur(tester);

    await tester.tap(find.text('Carré nord'));
    await tester.pumpAndSettle();

    // The detail shows its "Cultures" section header (absent from the plan).
    expect(find.text('Cultures'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
  });

  testWidgets('the header menu deletes the garden after confirmation',
      (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1', 'Carré nord')]);

    await monter(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le potager'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer ce potager ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    verify(() => potagers.supprimer('pot-1')).called(1);
  });

  testWidgets('the header menu hides multi-garden actions for a beginner',
      (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => []);

    await monter(tester); // débutant by default

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Changer de potager'), findsNothing);
    expect(find.text('Ajouter un potager'), findsNothing);
    expect(find.text('Modifier le potager'), findsOneWidget);
    expect(find.text('Supprimer le potager'), findsOneWidget);
  });

  testWidgets('switching garden from the picker persists the selection',
      (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => potagers.obtenirTous())
        .thenAnswer((_) async => [unPotager(), autrePotager()]);
    when(() => parcelles.obtenirParPotager(any()))
        .thenAnswer((_) async => []);

    await monter(tester, niveau: NiveauExperience.intermediaire);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changer de potager'));
    await tester.pumpAndSettle();

    expect(find.text('Mon potager'), findsOneWidget);
    expect(find.text('Jardin de la grand-mère'), findsOneWidget);

    await tester.tap(find.text('Jardin de la grand-mère'));
    await tester.pumpAndSettle();

    final saved =
        verify(() => preferences.sauvegarder(captureAny())).captured.single
            as PreferencesUtilisateur;
    expect(saved.potagerActifId, 'pot-2');
  });

  testWidgets('adding a garden creates it and switches to it', (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager(any()))
        .thenAnswer((_) async => []);
    when(() => potagers.sauvegarder(any())).thenAnswer((_) async {});
    when(() => geoloc.demanderPermission())
        .thenAnswer((_) async => PermissionLocalisation.accordee);
    when(() => geoloc.positionActuelle())
        .thenAnswer((_) async => Localisation.gps(latitude: 47, longitude: -1));

    await monter(tester, niveau: NiveauExperience.intermediaire);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un potager'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Second jardin');
    await tester.tap(find.text('Détecter ma position'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final cree =
        verify(() => potagers.sauvegarder(captureAny())).captured.single
            as Potager;
    expect(cree.nom, 'Second jardin');

    final saved =
        verify(() => preferences.sauvegarder(captureAny())).captured.single
            as PreferencesUtilisateur;
    expect(saved.potagerActifId, cree.id);

    expect(find.text('Potager créé.'), findsOneWidget);
  });

  testWidgets('offers to create a garden when there is none', (tester) async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);

    await monter(tester);

    expect(find.text('Crée ton premier potager pour commencer.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Créer un potager'), findsOneWidget);
  });
}
