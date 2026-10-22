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
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/teinte_zone.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/couleur_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/dimensions_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_zone.dart';
import 'package:pot_a_gerer/application/providers/unites_provider.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class _FakeParcelle extends Fake implements Parcelle {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeParcelle()));

  late MockParcelles repo;
  late MockPlantations plantations;

  setUp(() {
    repo = MockParcelles();
    plantations = MockPlantations();
    when(() => plantations.obtenirParParcelle(any()))
        .thenAnswer((_) async => []);
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
    when(() => repo.obtenirParPotager(any())).thenAnswer((_) async => []);
  });

  Future<void> monter(
    WidgetTester tester, {
    NiveauExperience niveau = NiveauExperience.debutant,
    PreferencesUnites unites = const PreferencesUnites(),
    Parcelle? initiale,
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
          plantationRepositoryProvider.overrideWithValue(plantations),
          accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
          unitesProvider.overrideWithValue(unites),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulaireZone(potagerId: 'pot-1', parcelleInitiale: initiale),
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

    // A round default in the field's own unit.
    expect(find.widgetWithText(TextFormField, 'Surface (ft²)'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

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

    await monter(tester, initiale: initiale);

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

  testWidgets('an untouched surface is saved as stored, whatever the unit',
      (tester) async {
    final initiale = Parcelle(
      id: 'z-8',
      nom: 'Carré',
      potagerId: 'pot-1',
      type: TypeParcelle.pot,
      surface: Surface.enMetresCarres(1),
      exposition: NiveauSoleil.pleinSoleil,
    );
    await monter(tester,
        initiale: initiale,
        unites: const PreferencesUnites.uniforme(SystemeUnites.imperial));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom de la zone'), 'Carré sud');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final parcelle =
        verify(() => repo.sauvegarder(captureAny())).captured.single as Parcelle;
    expect(parcelle.surface.enMetresCarres, 1);
  });

  group('dimensions and water need', () {
    Finder champ(String libelle) => find.widgetWithText(TextFormField, libelle);

    Future<Parcelle> enregistrer(WidgetTester tester) async {
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      return verify(() => repo.sauvegarder(captureAny())).captured.single
          as Parcelle;
    }

    Parcelle zone({DimensionsZone? dimensions, double m2 = 3}) => Parcelle(
          id: 'z-9',
          nom: 'Planche',
          potagerId: 'pot-1',
          type: TypeParcelle.pleineTerre,
          surface: dimensions?.surface ?? Surface.enMetresCarres(m2),
          exposition: NiveauSoleil.pleinSoleil,
          dimensions: dimensions,
          besoinEau: BesoinEau.modere,
        );

    testWidgets('both sides compute the surface, which locks', (tester) async {
      await monter(tester);
      await tester.enterText(champ('Nom de la zone'), 'Planche');
      await tester.enterText(champ('Longueur (m)'), '3');
      await tester.enterText(champ('Largeur (m)'), '1,2');
      await tester.pump();

      expect(find.text('3,6'), findsOneWidget);
      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: champ('Surface (m²)'), matching: find.byType(TextField)))
              .enabled,
          isFalse);

      final parcelle = await enregistrer(tester);
      expect(parcelle.dimensions,
          DimensionsZone(longueurCm: 300, largeurCm: 120));
      expect(parcelle.surface.enMetresCarres, closeTo(3.6, 1e-9));
    });

    testWidgets('a single side blocks saving', (tester) async {
      await monter(tester);
      await tester.enterText(champ('Nom de la zone'), 'Planche');
      await tester.enterText(champ('Longueur (m)'), '3');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Renseigner les deux côtés, ou aucun.'), findsOneWidget);
      verifyNever(() => repo.sauvegarder(any()));
    });

    testWidgets('imperial sides are typed in feet', (tester) async {
      await monter(tester,
          unites: const PreferencesUnites.uniforme(SystemeUnites.imperial));
      await tester.enterText(champ('Nom de la zone'), 'Planche');
      await tester.enterText(champ('Longueur (ft)'), '10');
      await tester.enterText(champ('Largeur (ft)'), '4');

      expect((await enregistrer(tester)).dimensions,
          DimensionsZone(longueurCm: 305, largeurCm: 122));
    });

    testWidgets('the water need is persisted', (tester) async {
      await monter(tester);
      await tester.enterText(champ('Nom de la zone'), 'Planche');
      await tester.tap(find.text('Non renseigné').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arrosage élevé').last);
      await tester.pumpAndSettle();

      expect((await enregistrer(tester)).besoinEau, BesoinEau.eleve);
    });

    testWidgets('edit keeps untouched dimensions and water need',
        (tester) async {
      final dimensions = DimensionsZone(longueurCm: 305, largeurCm: 122);
      await monter(tester,
          initiale: zone(dimensions: dimensions),
          unites: const PreferencesUnites.uniforme(SystemeUnites.imperial));
      await tester.enterText(champ('Nom de la zone'), 'Planche est');

      final parcelle = await enregistrer(tester);
      expect(parcelle.dimensions, dimensions);
      expect(parcelle.surface, dimensions.surface);
      expect(parcelle.besoinEau, BesoinEau.modere);
    });

    testWidgets('clearing both sides frees the surface again', (tester) async {
      await monter(tester,
          initiale:
              zone(dimensions: DimensionsZone(longueurCm: 200, largeurCm: 150)));
      await tester.enterText(champ('Longueur (m)'), '');
      await tester.enterText(champ('Largeur (m)'), '');
      await tester.enterText(champ('Surface (m²)'), '2');

      final parcelle = await enregistrer(tester);
      expect(parcelle.dimensions, isNull);
      expect(parcelle.surface.enMetresCarres, 2);
    });

    testWidgets('a surface below the crops in place is refused',
        (tester) async {
      when(() => plantations.obtenirParParcelle('z-9'))
          .thenAnswer((_) async => [
                Plantation(
                  id: 'p-1',
                  planteId: 'tomate',
                  parcelleId: 'z-9',
                  dateMiseEnPlace: DateTime(2026, 4, 1),
                  methode: MethodeMiseEnPlace.repiquage,
                  surfaceOccupee: Surface.enMetresCarres(2.5),
                  nombrePieds: 3,
                ),
              ]);
      await monter(tester, initiale: zone());
      await tester.enterText(champ('Surface (m²)'), '2');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Surface inférieure à celle des cultures en place (2,5 m²).'),
          findsOneWidget);
      verifyNever(() => repo.sauvegarder(any()));
    });
  });
}
