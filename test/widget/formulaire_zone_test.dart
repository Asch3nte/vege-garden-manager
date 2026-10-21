// Widget test for the zone-creation form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/teinte_zone.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/couleur_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_zone.dart';
import 'package:pot_a_gerer/application/providers/unites_provider.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';

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
    PreferencesUnites unites = const PreferencesUnites(),
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
          unitesProvider.overrideWithValue(unites),
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

  group('colour', () {
    Future<Parcelle> enregistrerZone(WidgetTester tester) async {
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom de la zone'), 'Carré nord');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      return verify(() => repo.sauvegarder(captureAny())).captured.last
          as Parcelle;
    }

    testWidgets('a new zone defaults to the first tint free in its garden',
        (tester) async {
      when(() => repo.obtenirParPotager('pot-1')).thenAnswer((_) async => [
            Parcelle(
              id: 'z-1',
              nom: 'Existante',
              potagerId: 'pot-1',
              type: TypeParcelle.pot,
              surface: Surface.enMetresCarres(1),
              exposition: NiveauSoleil.pleinSoleil,
            ),
          ]);
      await monter(tester);

      expect((await enregistrerZone(tester)).couleur,
          const CouleurZone.teinte(TeinteZone.terracotta));
    });

    testWidgets('a palette tint can be picked', (tester) async {
      await monter(tester);

      await tester.tap(find.bySemanticsLabel('Bordeaux'));
      await tester.pumpAndSettle();

      expect((await enregistrerZone(tester)).couleur,
          const CouleurZone.teinte(TeinteZone.bordeaux));
    });

    testWidgets('a custom colour is set from the RGB panel', (tester) async {
      await monter(tester);

      await tester.tap(find.bySemanticsLabel('Couleur personnalisée'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Code hexadécimal'), '#3366cc');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect((await enregistrerZone(tester)).couleur,
          CouleurZone.personnalisee(0x3366CC));
    });

    testWidgets('the RGB sliders and the hex code stay in sync',
        (tester) async {
      await monter(tester);

      await tester.tap(find.bySemanticsLabel('Couleur personnalisée'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Code hexadécimal'), 'FF0080');
      await tester.pumpAndSettle();

      final curseurs = tester.widgetList<Slider>(find.byType(Slider)).toList();
      expect(curseurs.map((c) => c.value), [255, 0, 128]);
    });

    testWidgets('an invalid hex code cannot be confirmed', (tester) async {
      await monter(tester);

      await tester.tap(find.bySemanticsLabel('Couleur personnalisée'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Code hexadécimal'), '#3A7');
      await tester.pumpAndSettle();

      expect(find.text('Format attendu : #RRGGBB'), findsOneWidget);
      expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Valider'))
              .onPressed,
          isNull);
    });

    testWidgets('a swatch is activable through accessibility', (tester) async {
      final semantique = tester.ensureSemantics();
      await monter(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Bordeaux')),
        matchesSemantics(
          label: 'Bordeaux',
          isButton: true,
          hasTapAction: true,
          hasSelectedState: true,
        ),
      );
      semantique.dispose();
    });

    testWidgets('cancelling the RGB panel keeps the previous colour',
        (tester) async {
      await monter(tester);

      await tester.tap(find.bySemanticsLabel('Couleur personnalisée'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Code hexadécimal'), '#3366CC');
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect((await enregistrerZone(tester)).couleur,
          const CouleurZone.teinte(TeinteZone.vertProfond));
    });
  });

  testWidgets('imperial surface is typed in ft² and stored in m²',
      (tester) async {
    await monter(tester,
        unites: const PreferencesUnites.uniforme(SystemeUnites.imperial));

    // The 1 m² default reads in ft².
    expect(find.widgetWithText(TextFormField, 'Surface (ft²)'), findsOneWidget);
    expect(find.text('10.76'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom de la zone'), 'Carré nord');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Surface (ft²)'), '21.5278');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final parcelle = verify(() => repo.sauvegarder(captureAny())).captured.single
        as Parcelle;
    expect(parcelle.surface.enMetresCarres, closeTo(2, 0.001));
  });

  testWidgets('a failed save reports it and re-enables the form',
      (tester) async {
    when(() => repo.sauvegarder(any()))
        .thenAnswer((_) async => throw Exception('disque plein'));
    await monter(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nom de la zone'), 'Carré nord');
    await tester.enterText(find.widgetWithText(TextFormField, 'Surface (m²)'), '2.5');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Enregistrement impossible. Réessayez.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enregistrer')).onPressed,
      isNotNull,
    );
  });

  testWidgets('type and exposure fields keep their glossary help icon',
      (tester) async {
    await monter(tester);

    expect(find.byIcon(PhosphorIconsRegular.question), findsNWidgets(2));
  });

  group('soil controls gating', () {
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
