// Widget tests for the equipment list screen: in-service rendering, the folded
// "retired" section, and the empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/equipement.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_equipement_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/glossaire/terme_cliquable.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_equipements.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockEquipements extends Mock implements AbstractEquipementRepository {}

void main() {
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockFiches fiches;
  late MockTaches taches;
  late MockEquipements equipements;

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      );

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    fiches = MockFiches();
    taches = MockTaches();
    equipements = MockEquipements();
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => potagers.obtenirTous()).thenAnswer((_) async => [unPotager()]);
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => plantations.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
  });

  Future<void> monter(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          plantationRepositoryProvider.overrideWithValue(plantations),
          tacheRepositoryProvider.overrideWithValue(taches),
          fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
          equipementRepositoryProvider.overrideWithValue(equipements),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranEquipements(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders in-service equipment and folds the retired ones',
      (tester) async {
    when(() => equipements.obtenirParPotager(any())).thenAnswer(
      (_) async => [
        Equipement(
          id: 'eq-1',
          nom: 'Oya du carré',
          potagerId: 'pot-1',
          type: TypeEquipement.oya,
          dateInstallation: DateTime(2026, 4, 1),
        ),
        Equipement(
          id: 'eq-2',
          nom: 'Vieux tuteur',
          potagerId: 'pot-1',
          type: TypeEquipement.tuteur,
          dateInstallation: DateTime(2024, 3, 1),
          dateRetrait: DateTime(2025, 11, 1),
        ),
      ],
    );

    await monter(tester);

    // In-service card and section.
    expect(find.text('En service'), findsOneWidget);
    expect(find.text('Oya du carré'), findsOneWidget);
    expect(find.text('Bon état'), findsOneWidget);
    expect(find.textContaining('Tout le potager'), findsOneWidget);
    // The type is a clickable term → its glossary "bible" page.
    expect(find.widgetWithText(TermeCliquable, 'Oya'), findsOneWidget);

    // Retired section is present but folded (its content not built yet).
    expect(find.text('Retirés'), findsOneWidget);
    expect(find.text('Vieux tuteur'), findsNothing);

    // Expanding reveals the retired equipment.
    await tester.tap(find.text('Retirés'));
    await tester.pumpAndSettle();
    expect(find.text('Vieux tuteur'), findsOneWidget);
  });

  testWidgets('shows the empty state when there is no equipment',
      (tester) async {
    when(() => equipements.obtenirParPotager(any()))
        .thenAnswer((_) async => []);

    await monter(tester);

    expect(find.text("Aucun équipement pour l'instant."), findsOneWidget);
  });
}
