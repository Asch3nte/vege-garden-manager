// Widget tests for the equipment create/edit form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/equipement.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/enums/etat_equipement.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_equipement_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_equipement.dart';

class MockEquipements extends Mock implements AbstractEquipementRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakeEquipement extends Fake implements Equipement {}

void main() {
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  setUpAll(() => registerFallbackValue(_FakeEquipement()));

  late MockEquipements equipements;
  late MockParcelles parcelles;

  setUp(() {
    equipements = MockEquipements();
    parcelles = MockParcelles();
    when(() => equipements.sauvegarder(any())).thenAnswer((_) async {});
    when(() => equipements.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
  });

  Parcelle uneParcelle(String id, String nom) => Parcelle(
        id: id,
        nom: nom,
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      );

  Future<void> monter(
    WidgetTester tester, {
    Equipement? initial,
    String? parcelleIdInitiale,
  }) async {
    // Tall surface so the whole scrollable form (incl. the save button) lays out.
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          equipementRepositoryProvider.overrideWithValue(equipements),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulaireEquipement(
            potagerId: 'pot-1',
            equipementInitial: initial,
            parcelleIdInitiale: parcelleIdInitiale,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('creates a transverse equipment with the defaults',
      (tester) async {
    await monter(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, "Nom de l'équipement"), 'Oya nord');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final equipement =
        verify(() => equipements.sauvegarder(captureAny())).captured.single
            as Equipement;
    expect(equipement.nom, 'Oya nord');
    expect(equipement.potagerId, 'pot-1');
    expect(equipement.type, TypeEquipement.oya);
    expect(equipement.etat, EtatEquipement.bon);
    expect(equipement.parcelleId, isNull); // transverse
    expect(equipement.dateInstallation, maintenant);
  });

  testWidgets('a blank name blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => equipements.sauvegarder(any()));
  });

  testWidgets('pre-attaches a creation to the given zone', (tester) async {
    when(() => parcelles.obtenirParPotager(any()))
        .thenAnswer((_) async => [uneParcelle('z-1', 'Carré nord')]);

    await monter(tester, parcelleIdInitiale: 'z-1');

    await tester.enterText(
        find.widgetWithText(TextFormField, "Nom de l'équipement"), 'Tuteur');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final equipement =
        verify(() => equipements.sauvegarder(captureAny())).captured.single
            as Equipement;
    expect(equipement.parcelleId, 'z-1');
  });

  testWidgets('edit mode pre-fills and preserves the retirement date',
      (tester) async {
    final initial = Equipement(
      id: 'eq-7',
      nom: 'Ancien voile',
      potagerId: 'pot-1',
      type: TypeEquipement.voileHivernage,
      dateInstallation: DateTime(2025, 3, 1),
      dateRetrait: DateTime(2025, 11, 1),
    );

    await monter(tester, initial: initial);

    expect(find.text("Modifier l'équipement"), findsOneWidget);
    expect(find.text('Ancien voile'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, "Nom de l'équipement"),
        'Nouveau voile');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final equipement =
        verify(() => equipements.sauvegarder(captureAny())).captured.single
            as Equipement;
    expect(equipement.id, 'eq-7'); // same identity (edit, not create)
    expect(equipement.nom, 'Nouveau voile');
    expect(equipement.type, TypeEquipement.voileHivernage);
    expect(equipement.dateRetrait, DateTime(2025, 11, 1)); // preserved
  });
}
