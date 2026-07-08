// Widget tests for the personal-sheet list screen: rendering a stored sheet
// (name, category, last-modified date) and the empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante_personnelle.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_personnelle_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/modele_fiche_personnelle.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_fiches_personnelles.dart';

class MockFichesPerso extends Mock
    implements AbstractFichePlantePersonnelleRepository {}

FichePlantePersonnelle _uneFiche() => FichePlantePersonnelle(
      id: 'fp-1',
      dateCreation: DateTime(2026, 5, 1),
      dateModification: DateTime(2026, 6, 9),
      contenu: ModeleFichePersonnelle(
        idFiche: 'perso_basilic_pourpre',
        categorie: CategoriePlante.aromatique,
        usages: const {UsagePlante.condimentaire},
        nomScientifique: 'Ocimum basilicum',
        familleBotanique: 'Lamiaceae',
        nomCommunFr: 'Basilic pourpre',
        ensoleillement: NiveauSoleil.pleinSoleil,
        arrosage: BesoinEau.modere,
        qualitesSol: const {QualiteSol.riche},
        phMin: 6,
        phMax: 7,
        espacementCm: 25,
        dureeAvantRecolteJoursMin: 40,
        dureeAvantRecolteJoursMax: 70,
      ),
    );

void main() {
  late MockFichesPerso repo;

  setUp(() {
    repo = MockFichesPerso();
  });

  Future<void> monter(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fichePlantePersonnelleRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranFichesPersonnelles(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a stored sheet with its category and modified date',
      (tester) async {
    when(() => repo.obtenirToutes()).thenAnswer((_) async => [_uneFiche()]);

    await monter(tester);

    expect(find.text('Basilic pourpre'), findsOneWidget);
    expect(find.text('Aromatiques'), findsOneWidget);
    expect(find.text('Modifiée le 09/06/2026'), findsOneWidget);
  });

  testWidgets('shows the empty state when there is no sheet', (tester) async {
    when(() => repo.obtenirToutes()).thenAnswer((_) async => []);

    await monter(tester);

    expect(find.text("Aucune fiche perso pour l'instant."), findsOneWidget);
  });
}
