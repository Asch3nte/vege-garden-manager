// Widget tests for the Potager zone-list screen.
//
// Overrides the repositories + the catalogue so the screen renders a known
// zone list, then checks the rendered rows, the task-today tag and the empty
// state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_potager.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

void main() {
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockFiches fiches;
  late MockTaches taches;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    fiches = MockFiches();
    taches = MockTaches();
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
  });

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
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

  Parcelle uneParcelle(String id, String nom, List<Plantation> plantations) =>
      Parcelle(
        id: id,
        nom: nom,
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
        plantations: plantations,
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

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          tacheRepositoryProvider.overrideWithValue(taches),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
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

  testWidgets('renders a row per zone with its crops', (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        uneParcelle('z-1', 'Carré nord', [unePlantation('p-1', 'tomate')]),
        uneParcelle('z-2', 'Serre', [unePlantation('p-2', 'aubergine')]),
      ],
    );
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

  testWidgets('shows the up-to-date tag when no task is due today',
      (tester) async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1', 'Carré nord', [])]);

    await monter(tester);

    expect(find.text('À jour'), findsOneWidget);
    expect(find.text('Tâche du jour'), findsNothing);
  });

  testWidgets('shows an empty state when there is no garden', (tester) async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);

    await monter(tester);

    expect(find.text('Aucun potager pour le moment.'), findsOneWidget);
  });
}
