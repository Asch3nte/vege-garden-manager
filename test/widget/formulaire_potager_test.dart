// Widget test for the garden-creation form.
//
// Fills the name, keeps the sensible climate/hardiness defaults, taps save and
// checks the garden is persisted (and the form pops the created entity).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/permission_localisation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_geolocalisation_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_potager.dart';

import '../helpers/globe.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockGeoloc extends Mock implements AbstractGeolocalisationService {}

class MockMeteo extends Mock implements AbstractMeteoService {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

class _FakePotager extends Fake implements Potager {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePotager());
    registerFallbackValue(const Localisation.nonDefinie());
  });

  late MockPotagers repo;
  late MockGeoloc geoloc;
  late MockMeteo meteo;

  setUp(() {
    repo = MockPotagers();
    geoloc = MockGeoloc();
    meteo = MockMeteo();
    when(() => meteo.obtenirElevation(any())).thenAnswer((_) async => null);
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
    when(() => repo.obtenirTous()).thenAnswer((_) async => []);
  });

  Future<void> monter(WidgetTester tester,
      {Potager? initial, List<Override> extra = const []}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(repo),
          geolocalisationServiceProvider.overrideWithValue(geoloc),
          meteoServiceProvider.overrideWithValue(meteo),
          ...extra,
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulairePotager(potagerInitial: initial),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('saving is blocked until a position is set', (tester) async {
    await monter(tester);
    expect(find.text('Aucune position'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Mon potager');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    // A garden must have a position (it derives hemisphere/climate); saving
    // without one is blocked, with the requirement message.
    expect(
      find.text("Indiquez d'abord la position de votre potager (GPS ou carte)."),
      findsOneWidget,
    );
    verifyNever(() => repo.sauvegarder(any()));
  });

  testWidgets('the climate field describes each option', (tester) async {
    await monter(tester);

    // Open the climate dropdown via its selected value (default oceanic).
    await tester.tap(find.text('Océanique'));
    await tester.pumpAndSettle();

    // The oceanic option carries its helper description in the menu.
    expect(find.text('Doux et humide, faibles écarts de température.'),
        findsOneWidget);
  });

  testWidgets('detecting the position pre-fills climate and stores it',
      (tester) async {
    when(() => geoloc.demanderPermission())
        .thenAnswer((_) async => PermissionLocalisation.accordee);
    when(() => geoloc.positionActuelle())
        .thenAnswer((_) async => Localisation.gps(latitude: 5, longitude: 10));
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await monter(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Potager tropical');
    await tester.tap(find.text('Détecter ma position'));
    await tester.pumpAndSettle();

    // The suggestion caption and the position with its origin are shown.
    expect(find.textContaining('pré-remplis depuis ta position'), findsWidgets);
    expect(find.text('Position GPS'), findsOneWidget);
    expect(find.text('5,0° N, 10,0° E'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final potager =
        verify(() => repo.sauvegarder(captureAny())).captured.single as Potager;
    // Latitude 5° → tropical / zone 11, and the position is stored.
    expect(potager.zoneClimatique.type, TypeClimat.tropical);
    expect(potager.zoneClimatique.rusticite, ZoneRusticite.zone11);
    expect(potager.localisation.estDefinie, isTrue);
  });

  testWidgets('picking a point on the world map pre-fills climate and stores '
      'the location', (tester) async {
    // Wide surface for the whole flow.
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await monter(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Potager');
    // Open the globe picker, pick a tropical point (drops the pin),
    // then confirm.
    await tester.tap(find.text('Choisir sur la carte'));
    await tester.pumpAndSettle();
    await choisirSurGlobe(tester, 5, 25);

    expect(find.textContaining('pré-remplis depuis ta position'), findsWidgets);
    expect(find.text('5,0° N, 25,0° E'), findsOneWidget);
    expect(find.text('Choisie sur le globe'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final potager =
        verify(() => repo.sauvegarder(captureAny())).captured.single as Potager;
    // Tropical region (latitude 5°) → tropical climate, location stored.
    expect(potager.zoneClimatique.type, TypeClimat.tropical);
    expect(potager.localisation.estDefinie, isTrue);
  });

  testWidgets('a refused permission leaves no position, so saving stays blocked',
      (tester) async {
    when(() => geoloc.demanderPermission())
        .thenAnswer((_) async => PermissionLocalisation.refusee);

    await monter(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Mon potager');
    await tester.tap(find.text('Détecter ma position'));
    await tester.pumpAndSettle();

    expect(find.text('Autorisation de localisation refusée.'), findsOneWidget);

    // Let the snackbar auto-dismiss so it no longer covers the save button.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    // No position was captured → save is blocked (no silent default).
    expect(
      find.text("Indiquez d'abord la position de votre potager (GPS ou carte)."),
      findsOneWidget,
    );
    verifyNever(() => repo.sauvegarder(any()));
  });

  testWidgets('edit mode pre-fills and persists the garden in place',
      (tester) async {
    when(() => repo.obtenirTous()).thenAnswer((_) async => []);
    final initial = Potager(
      id: 'pot-1',
      nom: 'Ancien nom',
      zoneClimatique:
          const ZoneClimatique(TypeClimat.mediterraneen, ZoneRusticite.zone9),
      localisation:
          Localisation.manuelle(ville: 'Nice', latitude: 43.7, longitude: 7.2),
      dateCreation: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(repo),
          geolocalisationServiceProvider.overrideWithValue(geoloc),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulairePotager(potagerInitial: initial),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modifier le potager'), findsOneWidget);
    expect(find.text('Ancien nom'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du potager'), 'Nouveau nom');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final potager =
        verify(() => repo.sauvegarder(captureAny())).captured.single as Potager;
    expect(potager.id, 'pot-1'); // same identity (edit, not create)
    expect(potager.nom, 'Nouveau nom');
    expect(potager.zoneClimatique.type, TypeClimat.mediterraneen); // preserved
  });

  testWidgets('a failed edit leaves the original garden untouched',
      (tester) async {
    when(() => repo.obtenirTous()).thenAnswer((_) async => []);
    when(() => repo.sauvegarder(any()))
        .thenAnswer((_) async => throw Exception('disque plein'));
    final initial = Potager(
      id: 'pot-1',
      nom: 'Ancien nom',
      zoneClimatique:
          const ZoneClimatique(TypeClimat.mediterraneen, ZoneRusticite.zone9),
      localisation:
          Localisation.manuelle(ville: 'Nice', latitude: 43.7, longitude: 7.2),
      dateCreation: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(repo),
          geolocalisationServiceProvider.overrideWithValue(geoloc),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulairePotager(potagerInitial: initial),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom du potager'), 'Nouveau nom');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(initial.nom, 'Ancien nom');
    expect(find.text('Enregistrement impossible. Réessayez.'), findsOneWidget);
  });

  testWidgets('an empty name blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => repo.sauvegarder(any()));
  });

  testWidgets('editing a garden shows its stored position and origin',
      (tester) async {
    await monter(tester,
        initial: Potager(
          id: 'pot-1',
          nom: 'Flémalle',
          zoneClimatique:
              const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
          dateCreation: DateTime(2026, 1, 1),
          localisation: Localisation.manuelle(
              ville: 'Haybes', latitude: 50, longitude: 4.71),
        ));

    expect(find.text('Haybes'), findsOneWidget);
    expect(find.text('Choisie sur le globe · 50,0° N, 4,7° E'), findsOneWidget);
  });

  testWidgets('the altitude refines the pre-filled climate and hardiness',
      (tester) async {
    final preferences = MockPreferences();
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    final position = Localisation.gps(latitude: 44.9, longitude: 6.64);
    when(() => meteo.obtenirElevation(position)).thenAnswer((_) async => 1326);
    when(() => geoloc.demanderPermission())
        .thenAnswer((_) async => PermissionLocalisation.accordee);
    when(() => geoloc.positionActuelle()).thenAnswer((_) async => position);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await monter(tester, extra: [
      preferencesRepositoryProvider.overrideWithValue(preferences),
    ]);
    await tester.enterText(find.byType(TextFormField).first, 'Briançon');
    await tester.tap(find.text('Détecter ma position'));
    await tester.pumpAndSettle();

    expect(find.text('Montagnard'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final potager =
        verify(() => repo.sauvegarder(captureAny())).captured.single as Potager;
    expect(potager.zoneClimatique.type, TypeClimat.montagnard);
    expect(potager.zoneClimatique.rusticite, ZoneRusticite.zone6);
  });

  testWidgets('a late altitude never overrides a climate picked by hand',
      (tester) async {
    final preferences = MockPreferences();
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    final position = Localisation.gps(latitude: 44.9, longitude: 6.64);
    final altitude = Completer<double?>();
    when(() => meteo.obtenirElevation(position))
        .thenAnswer((_) => altitude.future);
    when(() => geoloc.demanderPermission())
        .thenAnswer((_) async => PermissionLocalisation.accordee);
    when(() => geoloc.positionActuelle()).thenAnswer((_) async => position);
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await monter(tester, extra: [
      preferencesRepositoryProvider.overrideWithValue(preferences),
    ]);
    await tester.tap(find.text('Détecter ma position'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Méditerranéen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Océanique').last);
    await tester.pumpAndSettle();

    altitude.complete(1326);
    await tester.pumpAndSettle();
    expect(find.text('Océanique'), findsOneWidget);
    expect(find.text('Montagnard'), findsNothing);
  });
}
