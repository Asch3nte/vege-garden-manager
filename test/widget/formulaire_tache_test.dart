// Widget test for the task-creation form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/potager_notifier.dart';
import 'package:pot_a_gerer/application/state/potager_vue.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_tache.dart';

class MockTaches extends Mock implements AbstractTacheRepository {}

class _FakeTache extends Fake implements Tache {}

/// A fixed garden (one zone) so the form has targets without the repos.
class _FakePotager extends PotagerNotifier {
  @override
  Future<PotagerVue> build() async => PotagerVue(
        potagerId: 'pot-1',
        nomPotager: 'Mon potager',
        zones: [
          ZonePotager(
            id: 'z-1',
            nom: 'Carré nord',
            type: TypeParcelle.bacSureleve,
            surfaceM2: 2,
            exposition: NiveauSoleil.pleinSoleil,
            cultures: const [
              CulturePotager(plantationId: 'pl-9', nom: 'Tomate'),
            ],
          ),
        ],
      );
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  final maintenant = DateTime(2026, 6, 9, 8, 24);
  late MockTaches taches;

  setUp(() {
    taches = MockTaches();
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});
  });

  Future<void> monter(WidgetTester tester, {Tache? tacheInitiale}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tacheRepositoryProvider.overrideWithValue(taches),
          potagerProvider.overrideWith(_FakePotager.new),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FormulaireTache(tacheInitiale: tacheInitiale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('persists a task targeting the whole garden by default',
      (tester) async {
    await monter(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Intitulé'), 'Arroser les tomates');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final tache =
        verify(() => taches.sauvegarder(captureAny())).captured.single as Tache;
    expect(tache.titre, 'Arroser les tomates');
    expect(tache.type, TypeTache.arrosage); // default gesture
    expect(tache.cible, CibleTache.potager); // default target
    expect(tache.cibleId, 'pot-1');
    expect(tache.datePrevue, maintenant); // default date = today
  });

  testWidgets('edit mode pre-fills the form and persists the same id',
      (tester) async {
    final initiale = Tache(
      id: 't-42',
      titre: 'Arroser',
      type: TypeTache.arrosage,
      cible: CibleTache.parcelle,
      cibleId: 'z-1',
      datePrevue: DateTime(2026, 6, 12),
    );

    await monter(tester, tacheInitiale: initiale);

    // Pre-filled with the existing title and the edit title bar.
    expect(find.text('Modifier la tâche'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Arroser'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Arroser'), 'Arroser le matin');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final tache =
        verify(() => taches.sauvegarder(captureAny())).captured.single as Tache;
    expect(tache.id, 't-42'); // same identity → updates, not a new task
    expect(tache.titre, 'Arroser le matin');
    expect(tache.cible, CibleTache.parcelle);
    expect(tache.cibleId, 'z-1');
  });

  testWidgets('can target a specific crop (tâche↔plantation link)',
      (tester) async {
    await monter(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Intitulé'), 'Tuteurer la tomate');
    // Open the target dropdown (showing the default "whole garden") and pick
    // the crop, listed under its zone.
    await tester.tap(find.text('Tout le potager'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carré nord › Tomate').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final tache =
        verify(() => taches.sauvegarder(captureAny())).captured.single as Tache;
    expect(tache.cible, CibleTache.plantation);
    expect(tache.cibleId, 'pl-9');
  });

  testWidgets('an empty title blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => taches.sauvegarder(any()));
  });
}
