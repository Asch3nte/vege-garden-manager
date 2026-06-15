// Widget test for the zone-creation form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_zone.dart';

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakeParcelle extends Fake implements Parcelle {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeParcelle()));

  late MockParcelles repo;

  setUp(() {
    repo = MockParcelles();
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
    when(() => repo.obtenirParPotager(any())).thenAnswer((_) async => []);
  });

  Future<void> monter(
    WidgetTester tester, {
    NiveauExperience niveau = NiveauExperience.debutant,
  }) async {
    // Tall surface so the whole (scrollable) form — including the gated soil
    // controls and the save button — is laid out without lazy off-screen drops.
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parcelleRepositoryProvider.overrideWithValue(repo),
          accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FormulaireZone(potagerId: 'pot-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('persists a zone with name, surface and defaults', (tester) async {
    await monter(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nom de la zone'), 'Carré nord');
    await tester.enterText(find.widgetWithText(TextFormField, 'Surface (m²)'), '2.5');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final parcelle = verify(() => repo.sauvegarder(captureAny())).captured.single as Parcelle;
    expect(parcelle.nom, 'Carré nord');
    expect(parcelle.potagerId, 'pot-1');
    expect(parcelle.surface.enMetresCarres, 2.5);
    expect(parcelle.exposition, NiveauSoleil.pleinSoleil);
  });

  group('soil controls gating (ADR-0009)', () {
    testWidgets('a beginner sees no soil controls', (tester) async {
      await monter(tester); // débutant

      expect(find.text('Techniques de sol'), findsNothing);
      expect(find.text('Texture du sol'), findsNothing);
      expect(find.text('pH du sol'), findsNothing);
    });

    testWidgets('intermediate unlocks techniques (but not texture/pH)',
        (tester) async {
      await monter(tester, niveau: NiveauExperience.intermediaire);

      expect(find.text('Techniques de sol'), findsOneWidget);
      expect(find.text('Texture du sol'), findsNothing);
    });

    testWidgets('expert unlocks texture and pH', (tester) async {
      await monter(tester, niveau: NiveauExperience.expert);

      expect(find.text('Techniques de sol'), findsOneWidget);
      expect(find.text('Texture du sol'), findsOneWidget);
      expect(find.text('pH du sol'), findsOneWidget);
    });

    testWidgets('a selected technique is persisted', (tester) async {
      await monter(tester, niveau: NiveauExperience.intermediaire);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom de la zone'), 'Butte');
      await tester.tap(find.widgetWithText(FilterChip, 'Paillage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final parcelle =
          verify(() => repo.sauvegarder(captureAny())).captured.single
              as Parcelle;
      expect(parcelle.techniquesSol, contains(TechniqueSol.paillage));
    });
  });

  testWidgets('a non-positive surface blocks saving', (tester) async {
    await monter(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nom de la zone'), 'X');
    await tester.enterText(find.widgetWithText(TextFormField, 'Surface (m²)'), '0');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Saisis un nombre supérieur à 0.'), findsOneWidget);
    verifyNever(() => repo.sauvegarder(any()));
  });

  testWidgets('edit mode pre-fills and persists, preserving untouched fields',
      (tester) async {
    final initiale = Parcelle(
      id: 'z-7',
      nom: 'Ancien nom',
      potagerId: 'pot-1',
      type: TypeParcelle.serre,
      surface: Surface.enMetresCarres(3),
      exposition: NiveauSoleil.miOmbre,
      notes: 'mémo sol',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [parcelleRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulaireZone(potagerId: 'pot-1', parcelleInitiale: initiale),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pre-filled from the existing zone.
    expect(find.text('Modifier la zone'), findsOneWidget);
    expect(find.text('Ancien nom'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom de la zone'), 'Nouveau nom');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final parcelle =
        verify(() => repo.sauvegarder(captureAny())).captured.single as Parcelle;
    expect(parcelle.id, 'z-7'); // same identity (edit, not create)
    expect(parcelle.nom, 'Nouveau nom');
    expect(parcelle.type, TypeParcelle.serre);
    expect(parcelle.notes, 'mémo sol'); // untouched field preserved
  });
}
