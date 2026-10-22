// Widget tests for the globe position picker opened by [choisirSurCarteMonde]:
// place search, tap on the globe, footer naming and the returned location.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/source_localisation.dart';
import 'package:pot_a_gerer/domain/exceptions/geocodage_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_geocodage_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/lieu_trouve.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/globe/globe_terrestre.dart';
import 'package:pot_a_gerer/presentation/widgets/selecteur_carte_monde.dart';

class _MockGeocodage extends Mock implements AbstractGeocodageService {}

class _MockPreferences extends Mock implements AbstractPreferencesRepository {}

void main() {
  late _MockGeocodage geocodage;
  late _MockPreferences preferences;
  late List<Localisation?> capture;

  final namur = LieuTrouve(
      nom: 'Namur',
      region: 'Wallonie',
      pays: 'Belgique',
      latitude: 50.4669,
      longitude: 4.8675);
  final namurUsa = LieuTrouve(
      nom: 'Namur',
      region: 'Wisconsin',
      pays: 'États-Unis',
      latitude: 44.8,
      longitude: -87.5);

  setUp(() {
    geocodage = _MockGeocodage();
    preferences = _MockPreferences();
    when(() => preferences.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    capture = [];
  });

  Future<void> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        geocodageServiceProvider.overrideWithValue(geocodage),
        preferencesRepositoryProvider.overrideWithValue(preferences),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async =>
                    capture.add(await choisirSurCarteMonde(context)),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  Future<void> rechercher(WidgetTester tester, String texte) async {
    await tester.enterText(find.byType(TextField), texte);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  bool validerActif(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

  Future<Localisation> valider(WidgetTester tester) async {
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    return capture.single!;
  }

  testWidgets('starts with a search field, the globe and nothing chosen',
      (tester) async {
    await ouvrir(tester);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(GlobeTerrestre), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Aucune position choisie'), findsOneWidget);
    expect(validerActif(tester), isFalse);
  });

  testWidgets('a single match drops the pin and names the footer',
      (tester) async {
    when(() => geocodage.rechercherLieux('Namur'))
        .thenAnswer((_) async => [namur]);
    await ouvrir(tester);

    await rechercher(tester, 'Namur');

    expect(find.byIcon(PhosphorIconsBold.mapPin), findsOneWidget);
    expect(find.text('Namur'), findsWidgets);
    expect(find.textContaining('Wallonie, Belgique'), findsOneWidget);
    final loc = await valider(tester);
    expect(loc.ville, 'Namur');
    expect(loc.source, SourceLocalisation.manuelle);
    expect(loc.latitude, 50.47);
    expect(loc.longitude, 4.87);
    verifyNever(() => geocodage.identifierLieu(any(), any()));
  });

  testWidgets('several matches list suggestions with region and country',
      (tester) async {
    when(() => geocodage.rechercherLieux('Namur'))
        .thenAnswer((_) async => [namur, namurUsa]);
    await ouvrir(tester);

    await rechercher(tester, 'Namur');

    expect(find.text('Wallonie, Belgique'), findsOneWidget);
    expect(find.text('Wisconsin, États-Unis'), findsOneWidget);
    expect(validerActif(tester), isFalse);

    await tester.tap(find.text('Wisconsin, États-Unis'));
    await tester.pumpAndSettle();

    expect(find.text('Wallonie, Belgique'), findsNothing);
    final loc = await valider(tester);
    expect(loc.latitude, 44.8);
    expect(loc.longitude, -87.5);
  });

  testWidgets('no match says so', (tester) async {
    when(() => geocodage.rechercherLieux(any())).thenAnswer((_) async => []);
    await ouvrir(tester);
    await rechercher(tester, 'Zzz');
    expect(find.text('Aucune localité trouvée.'), findsOneWidget);
  });

  testWidgets('an unreachable service says so and leaves the globe usable',
      (tester) async {
    when(() => geocodage.rechercherLieux(any()))
        .thenThrow(GeocodageIndisponibleException('offline'));
    await ouvrir(tester);
    await rechercher(tester, 'Namur');
    expect(find.textContaining('Recherche indisponible'), findsOneWidget);
  });

  testWidgets('a blank search sends nothing', (tester) async {
    await ouvrir(tester);
    await rechercher(tester, '   ');
    verifyNever(() => geocodage.rechercherLieux(any()));
  });

  testWidgets('a tap on the globe pins the point and names it',
      (tester) async {
    when(() => geocodage.identifierLieu(any(), any())).thenAnswer((i) async =>
        LieuTrouve(
            nom: 'Ghardaïa',
            pays: 'Algérie',
            latitude: i.positionalArguments[0] as double,
            longitude: i.positionalArguments[1] as double));
    await ouvrir(tester);

    await tester.tapAt(tester.getCenter(find.byType(GlobeTerrestre)));
    await tester.pump();
    expect(find.byIcon(PhosphorIconsBold.mapPin), findsOneWidget);
    expect(find.text('Recherche du nom…'), findsOneWidget);
    expect(validerActif(tester), isTrue);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Ghardaïa'), findsOneWidget);
    expect(find.textContaining('Algérie'), findsOneWidget);
    verify(() => geocodage.identifierLieu(any(), any())).called(1);

    final loc = await valider(tester);
    expect(loc.ville, 'Ghardaïa');
  });

  testWidgets('quick successive taps name only the last point',
      (tester) async {
    when(() => geocodage.identifierLieu(any(), any()))
        .thenAnswer((_) async => null);
    await ouvrir(tester);
    final centre = tester.getCenter(find.byType(GlobeTerrestre));

    await tester.tapAt(centre);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(centre + const Offset(30, 0));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    verify(() => geocodage.identifierLieu(any(), any())).called(1);
  });

  testWidgets('an unnamed point is stored under its coordinates',
      (tester) async {
    when(() => geocodage.identifierLieu(any(), any()))
        .thenAnswer((_) async => null);
    await ouvrir(tester);

    await tester.tapAt(tester.getCenter(find.byType(GlobeTerrestre)));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    final loc = await valider(tester);
    expect(loc.ville, matches(RegExp(r'^\d+\.\d° [NS], \d+\.\d° [EO]$')));
  });

  testWidgets('with automatic network calls off, a tapped point is not named',
      (tester) async {
    when(() => preferences.charger()).thenAnswer(
        (_) async => PreferencesUtilisateur(meteoAutoActive: false));
    await ouvrir(tester);

    await tester.tapAt(tester.getCenter(find.byType(GlobeTerrestre)));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Recherche du nom…'), findsNothing);
    verifyNever(() => geocodage.identifierLieu(any(), any()));
    final loc = await valider(tester);
    expect(loc.ville, matches(RegExp(r'^\d+\.\d° [NS], \d+\.\d° [EO]$')));
  });

  testWidgets('a search started while a point is being named keeps its name',
      (tester) async {
    when(() => geocodage.identifierLieu(any(), any())).thenAnswer((_) async =>
        LieuTrouve(nom: 'Ghardaïa', latitude: 30, longitude: 10));
    when(() => geocodage.rechercherLieux(any())).thenAnswer((_) async => []);
    await ouvrir(tester);

    await tester.tapAt(tester.getCenter(find.byType(GlobeTerrestre)));
    await tester.pump();
    await rechercher(tester, 'Zzz');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Ghardaïa'), findsOneWidget);
    expect(find.text('Recherche du nom…'), findsNothing);
  });
}
