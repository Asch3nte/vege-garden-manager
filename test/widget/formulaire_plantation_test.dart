// Widget test for the plantation-creation form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_plantation.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class _FakePlantation extends Fake implements Plantation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePlantation()));

  late MockFiches fiches;
  late MockPlantations plantations;

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
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [fiche('tomate', 'Tomate')]);
    when(() => plantations.sauvegarder(any())).thenAnswer((_) async {});
    when(() => plantations.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          plantationRepositoryProvider.overrideWithValue(plantations),
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
    await tester.tap(find.text('Plante'));
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

  testWidgets('not choosing a plant blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => plantations.sauvegarder(any()));
  });
}
