// Widget test for the garden-creation form.
//
// Fills the name, keeps the sensible climate/hardiness defaults, taps save and
// checks the garden is persisted (and the form pops the created entity).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockGeoloc extends Mock implements AbstractGeolocalisationService {}

class _FakePotager extends Fake implements Potager {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePotager()));

  late MockPotagers repo;
  late MockGeoloc geoloc;

  setUp(() {
    repo = MockPotagers();
    geoloc = MockGeoloc();
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
    when(() => repo.obtenirTous()).thenAnswer((_) async => []);
  });

  Future<void> monter(WidgetTester tester) async {
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
          home: const FormulairePotager(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('saving is blocked until a position is set', (tester) async {
    await monter(tester);

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

    await monter(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Potager tropical');
    await tester.tap(find.text('Détecter ma position'));
    await tester.pumpAndSettle();

    // The suggestion caption is shown.
    expect(find.textContaining('pré-remplis depuis ta position'), findsWidgets);

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
    // Wide surface so the region band's presets fit without horizontal scroll.
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await monter(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Potager');
    // Open the zoomable world map, jump to a region preset (drops the pin),
    // then confirm.
    await tester.tap(find.text('Choisir sur la carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone tropicale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.textContaining('pré-remplis depuis ta position'), findsWidgets);

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

  testWidgets('an empty name blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => repo.sauvegarder(any()));
  });
}
