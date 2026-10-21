// Widget test for the plantation-creation form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_famille_botanique_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_plantation.dart';
import 'package:pot_a_gerer/application/providers/unites_provider.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';
import '../helpers/favoris_mock.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakePlantation extends Fake implements Plantation {}

class _MockFamilles extends Mock implements AbstractFamilleBotaniqueRepository {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePlantation()));

  late MockFiches fiches;
  late MockPlantations plantations;
  late MockParcelles parcelles;

  FichePlante fiche(String id, String nomFr) => FichePlante(
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

  setUp(() {
    fiches = MockFiches();
    plantations = MockPlantations();
    parcelles = MockParcelles();
    when(() => parcelles.obtenirParId('z-1')).thenAnswer((_) async => Parcelle(
          id: 'z-1',
          nom: 'Bac',
          potagerId: 'pot1',
          type: TypeParcelle.bacSureleve,
          surface: Surface.enMetresCarres(4),
          exposition: NiveauSoleil.pleinSoleil,
        ));
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [fiche('tomate', 'Tomate')]);
    when(() => plantations.sauvegarder(any())).thenAnswer((_) async {});
    when(() => plantations.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
  });

  Future<void> monter(WidgetTester tester,
      {PreferencesUnites unites = const PreferencesUnites()}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriRepositoryProvider.overrideWithValue(favorisEnMemoire()),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          familleBotaniqueRepositoryProvider.overrideWith((ref) async {
            final familles = _MockFamilles();
            when(familles.obtenirToutes).thenAnswer((_) async => []);
            return familles;
          }),
          plantationRepositoryProvider.overrideWithValue(plantations),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          unitesProvider.overrideWithValue(unites),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FormulairePlantation(parcelleId: 'z-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('persists a plantation for the chosen plant', (tester) async {
    await monter(tester);

    // Pick the plant from the catalogue dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<FichePlante>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final plantation =
        verify(() => plantations.sauvegarder(captureAny())).captured.single
            as Plantation;
    expect(plantation.planteId, 'tomate');
    expect(plantation.parcelleId, 'z-1');
    expect(plantation.nombrePieds, 1);
  });

  testWidgets('a zone without room refuses the plantation with a reason',
      (tester) async {
    when(() => plantations.obtenirParParcelle(any())).thenAnswer((_) async => [
          Plantation(
            id: 'en-place',
            planteId: 'courge',
            parcelleId: 'z-1',
            dateMiseEnPlace: DateTime(2026, 5, 1),
            methode: MethodeMiseEnPlace.repiquage,
            surfaceOccupee: Surface.enMetresCarres(3.75),
            nombrePieds: 1,
          ),
        ]);
    await monter(tester);
    await tester.tap(find.byType(DropdownButtonFormField<FichePlante>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '0,5'), '1');

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Plus assez de place dans cette zone : 0,25 m² libres.'),
        findsOneWidget);
    verifyNever(() => plantations.sauvegarder(any()));
  });

  testWidgets('imperial surface is typed in ft², stored and checked in m²',
      (tester) async {
    when(() => plantations.obtenirParParcelle(any())).thenAnswer((_) async => [
          Plantation(
            id: 'en-place',
            planteId: 'courge',
            parcelleId: 'z-1',
            dateMiseEnPlace: DateTime(2026, 5, 1),
            methode: MethodeMiseEnPlace.repiquage,
            surfaceOccupee: Surface.enMetresCarres(3.75),
            nombrePieds: 1,
          ),
        ]);
    await monter(tester,
        unites: const PreferencesUnites.uniforme(SystemeUnites.imperial));
    await tester.tap(find.byType(DropdownButtonFormField<FichePlante>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Surface occupée (ft²)'),
        findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Surface occupée (ft²)'), '20');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    // 20 ft² ≈ 1.86 m² does not fit in the 0.25 m² left, shown in ft².
    expect(find.text('Plus assez de place dans cette zone : 2,7 ft² libres.'),
        findsOneWidget);
    verifyNever(() => plantations.sauvegarder(any()));
  });

  testWidgets('the planting-type field is renamed and describes each option',
      (tester) async {
    await monter(tester);

    // Renamed away from the confusing "Méthode".
    expect(find.text('Type de mise en place'), findsOneWidget);
    expect(find.text('Méthode'), findsNothing);

    // Opening it (via its selected value) reveals a description per option.
    await tester.tap(find.text('Semis direct'));
    await tester.pumpAndSettle();
    expect(find.text('Semer la graine directement en place, au jardin.'),
        findsOneWidget);
  });

  testWidgets('not choosing a plant blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => plantations.sauvegarder(any()));
  });

  testWidgets('a pre-selected plant is locked and persisted without picking',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriRepositoryProvider.overrideWithValue(favorisEnMemoire()),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          familleBotaniqueRepositoryProvider.overrideWith((ref) async {
            final familles = _MockFamilles();
            when(familles.obtenirToutes).thenAnswer((_) async => []);
            return familles;
          }),
          plantationRepositoryProvider.overrideWithValue(plantations),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulairePlantation(
            parcelleId: 'z-1',
            planteInitiale: fiche('tomate', 'Tomate'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The plant is shown locked (no dropdown to open), so saving works directly.
    expect(find.byIcon(PhosphorIconsRegular.lock), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final plantation =
        verify(() => plantations.sauvegarder(captureAny())).captured.single
            as Plantation;
    expect(plantation.planteId, 'tomate');
    expect(plantation.parcelleId, 'z-1');
  });
}
