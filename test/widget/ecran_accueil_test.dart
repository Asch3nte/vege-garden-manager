// Widget tests for the Accueil dashboard screen.
//
// Overrides the four repositories + the clock so the screen renders a known
// view-model, then checks the rendered sections and the progressive-disclosure
// rule (season stats unlock at expert level).
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
import 'package:pot_a_gerer/domain/repositories/abstract_geolocalisation_service.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_alerte_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/alerte_culture.dart';
import 'package:pot_a_gerer/presentation/providers/notifications_accueil_provider.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_recolte_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_notifier.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_vue.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_accueil.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_zone_detail.dart';

/// Fixed weather view so the card renders a known verdict.
class _FakeMeteo extends MeteoAccueilNotifier {
  @override
  Future<MeteoAccueilVue> build() async => MeteoAccueilVue.disponible(
        tempMin: 12,
        tempMax: 24,
        verdict: VerdictMeteo.pluieAVenir,
      );
}

/// Weather unavailable → the card shows the "set a position" prompt.
class _FakeMeteoIndispo extends MeteoAccueilNotifier {
  @override
  Future<MeteoAccueilVue> build() async => MeteoAccueilVue.indisponible();
}

/// Automatic weather off → the card shows the neutral "weather off" state.
class _FakeMeteoDesactivee extends MeteoAccueilNotifier {
  @override
  Future<MeteoAccueilVue> build() async => MeteoAccueilVue.desactivee();
}

class _MockGeoloc extends Mock implements AbstractGeolocalisationService {}

class _FakePotager extends Fake implements Potager {}

class _FakeTache extends Fake implements Tache {}

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockRecoltes extends Mock implements AbstractRecolteRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

class _StubGenererTachesArrosage implements GenererTachesArrosage {
  @override
  Future<void> executer() async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePotager());
    registerFallbackValue(_FakeTache());
  });

  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockTaches taches;
  late MockPreferences preferences;
  late MockPlantations plantations;
  late MockFiches fiches;
  late MockRecoltes recoltes;
  late MockMeteo meteo;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    taches = MockTaches();
    preferences = MockPreferences();
    plantations = MockPlantations();
    fiches = MockFiches();
    recoltes = MockRecoltes();
    meteo = MockMeteo();
    when(() => plantations.obtenirParParcelle(any())).thenAnswer((_) async => []);
    when(() => recoltes.obtenirParPlantation(any())).thenAnswer((_) async => []);

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
          surface: Surface.enMetresCarres(1),
          exposition: NiveauSoleil.pleinSoleil,
        ),
      ],
    );
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        Tache(
          id: 't-1',
          titre: 'Arroser les tomates',
          type: TypeTache.arrosage,
          cible: CibleTache.parcelle,
          cibleId: 'z-1',
          datePrevue: maintenant,
        ),
      ],
    );
  });

  // All repositories the dashboard view-model reads (built per test for the
  // mocks assigned in setUp).
  base() => [
        potagerRepositoryProvider.overrideWithValue(potagers),
        parcelleRepositoryProvider.overrideWithValue(parcelles),
        tacheRepositoryProvider.overrideWithValue(taches),
        preferencesRepositoryProvider.overrideWithValue(preferences),
        plantationRepositoryProvider.overrideWithValue(plantations),
        recolteRepositoryProvider.overrideWithValue(recoltes),
        meteoServiceProvider.overrideWithValue(meteo),
        fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
        horlogeProvider.overrideWithValue(() => maintenant),
        genererTachesArrosageProvider
            .overrideWith((ref) async => _StubGenererTachesArrosage()),
      ];

  Future<void> monter(WidgetTester tester, NiveauExperience niveau) async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(niveauExperience: niveau),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: base(),
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders today\'s tasks and the garden overview', (tester) async {
    await monter(tester, NiveauExperience.intermediaire);

    expect(find.text('Tâches du jour'), findsOneWidget);
    expect(find.text('Arroser les tomates'), findsOneWidget);
    expect(find.text('Aperçu du potager'), findsOneWidget);
    expect(find.text('Carré nord'), findsOneWidget);
  });

  testWidgets('season stats stay locked below expert level', (tester) async {
    await monter(tester, NiveauExperience.intermediaire);

    expect(find.text('Statistiques au niveau Expert'), findsOneWidget);
    expect(find.text('Récoltes de la saison à venir'), findsNothing);
  });

  testWidgets('season stats unlock at expert level', (tester) async {
    await monter(tester, NiveauExperience.expert);

    // No harvests recorded → the season tile shows its zero-count label.
    expect(find.text('Aucune récolte cette saison'), findsOneWidget);
    expect(find.text('Statistiques au niveau Expert'), findsNothing);
  });

  testWidgets('error state offers a retry', (tester) async {
    when(() => preferences.charger()).thenThrow(Exception('boom'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: base(),
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('tapping a task on the dashboard toggles it', (tester) async {
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await monter(tester, NiveauExperience.intermediaire);

    await tester.tap(find.text('Arroser les tomates'));
    await tester.pumpAndSettle();

    final tache =
        verify(() => taches.sauvegarder(captureAny())).captured.single as Tache;
    expect(tache.estFaite, isTrue); // toggled to done
  });

  testWidgets('the weather card shows the temperatures and the verdict',
      (tester) async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...base(), meteoAccueilProvider.overrideWith(_FakeMeteo.new)],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12° – 24°'), findsOneWidget);
    expect(find.text("Pluie à venir — l'arrosage peut attendre."), findsOneWidget);
  });

  testWidgets('automatic weather off shows the neutral disabled card',
      (tester) async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base(),
          meteoAccueilProvider.overrideWith(_FakeMeteoDesactivee.new),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Météo automatique désactivée'), findsOneWidget);
    // Not the misleading "add a position" prompt (a position is set).
    expect(find.textContaining('Ajoute ta position'), findsNothing);
  });

  testWidgets('the weather prompt sets the garden position', (tester) async {
    // Wide surface so the map's region band fits without horizontal scrolling.
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.sauvegarder(any())).thenAnswer((_) async {});
    when(() => potagers.obtenirTous()).thenAnswer((_) async => []);
    final geoloc = _MockGeoloc();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base(),
          geolocalisationServiceProvider.overrideWithValue(geoloc),
          meteoAccueilProvider.overrideWith(_FakeMeteoIndispo.new),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The card invites to set a position; tapping it opens the capture sheet.
    await tester.tap(find.textContaining('Ajoute ta position'));
    await tester.pumpAndSettle();

    // Sheet → open the world map → jump to a region preset → confirm. The
    // chosen position is stored on the active garden.
    await tester.tap(find.text('Choisir sur la carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone tropicale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final potager =
        verify(() => potagers.sauvegarder(captureAny())).captured.last as Potager;
    expect(potager.localisation.estDefinie, isTrue);
  });

  testWidgets('tapping a zone tile opens its detail on the Potager branch',
      (tester) async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(),
    );
    // The dashboard tile now targets the zone detail under the Potager branch
    // (docs/15 §8 D #5); the cross-branch "back returns to the dashboard"
    // behaviour belongs to the real shell and is covered in navigation_test.
    final router = GoRouter(
      initialLocation: RoutesApp.accueil,
      routes: [
        GoRoute(
          path: RoutesApp.accueil,
          builder: (context, state) => const EcranAccueil(),
        ),
        GoRoute(
          path: RoutesApp.potager,
          builder: (context, state) => const Scaffold(body: Text('Plan')),
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
        overrides: base(),
        child: MaterialApp.router(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carré nord'));
    await tester.pumpAndSettle();

    // The zone-detail screen is shown (its "Cultures" section header).
    expect(find.widgetWithText(AppBar, 'Carré nord'), findsOneWidget);
    expect(find.text('Cultures'), findsOneWidget);
  });

  testWidgets('the header bell opens the notifications panel (alerts + tasks)',
      (tester) async {
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    final vue = NotificationsAccueilVue(
      alertes: [
        AlerteCulture(
          type: TypeAlerteMeteo.gel,
          date: DateTime(2026, 7, 12),
          valeurDeclenchante: -2,
          plantationsConcernees: const ['p-1'],
        ),
      ],
      tachesUrgentes: [
        Tache(
          id: 't-urg',
          titre: 'Arroser d\'urgence',
          type: TypeTache.arrosage,
          cible: CibleTache.plantation,
          cibleId: 'p-1',
          datePrevue: DateTime(2026, 7, 12),
          priorite: PrioriteTache.urgente,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base(),
          notificationsAccueilProvider.overrideWith((ref) async => vue),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    // The panel lists both sections with their content.
    expect(find.text('Alertes météo'), findsOneWidget);
    expect(find.textContaining('Gel le 12/07'), findsOneWidget);
    expect(find.text('Tâches urgentes'), findsOneWidget);
    expect(find.text('Arroser d\'urgence'), findsOneWidget);
  });

  testWidgets('the header overflow menu lists notification and help shortcuts',
      (tester) async {
    await monter(tester, NiveauExperience.intermediaire);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Aide & lexique'), findsOneWidget);
  });

  testWidgets('the tasks header link opens the Calendar tab', (tester) async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(),
    );
    final router = GoRouter(
      initialLocation: RoutesApp.accueil,
      routes: [
        GoRoute(
          path: RoutesApp.accueil,
          builder: (context, state) => const EcranAccueil(),
        ),
        GoRoute(
          path: RoutesApp.calendrier,
          builder: (context, state) =>
              const Scaffold(body: Text('Écran calendrier')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: base(),
        child: MaterialApp.router(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voir le calendrier'));
    await tester.pumpAndSettle();

    expect(find.text('Écran calendrier'), findsOneWidget);
  });
}
