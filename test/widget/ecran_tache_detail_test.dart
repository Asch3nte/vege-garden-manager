// Widget tests for the task-detail screen. Overrides the task repositories so
// the detail view-model loads a known task, then checks rendering and one edit.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/priorite_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_tache_detail.dart';

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class _FakeTache extends Fake implements Tache {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  late MockTaches taches;
  late MockParcelles parcelles;

  setUp(() {
    taches = MockTaches();
    parcelles = MockParcelles();
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});
    when(() => parcelles.obtenirParId('z-1')).thenAnswer(
      (_) async => Parcelle(
        id: 'z-1',
        nom: 'Carré nord',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(1),
        exposition: NiveauSoleil.pleinSoleil,
      ),
    );
  });

  Tache uneTache({String? notes}) => Tache(
        id: 't-1',
        titre: 'Arroser : Tomate',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: DateTime(2026, 6, 9),
        etat: EtatTache.aFaire,
        priorite: PrioriteTache.normale,
        notes: notes,
      );

  Widget app() => ProviderScope(
        overrides: [
          tacheRepositoryProvider.overrideWithValue(taches),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          horlogeProvider.overrideWithValue(() => DateTime(2026, 6, 9, 10)),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranTacheDetail(tacheId: 't-1'),
        ),
      );

  testWidgets('renders the task, target and priority', (tester) async {
    when(() => taches.obtenirParId('t-1')).thenAnswer((_) async => uneTache());

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Arroser : Tomate'), findsOneWidget);
    expect(find.text('Carré nord'), findsOneWidget); // resolved target
    expect(find.text('À faire'), findsOneWidget); // state chip
    expect(find.text('Aucune note pour le moment.'), findsOneWidget);
  });

  testWidgets('editing the notes persists them', (tester) async {
    when(() => taches.obtenirParId('t-1')).thenAnswer((_) async => uneTache());

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Open the inline notes editor (the "Ajouter" button of the notes section).
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Arroser au pied le matin');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final saved =
        verify(() => taches.sauvegarder(captureAny())).captured.single as Tache;
    expect(saved.notes, 'Arroser au pied le matin');
  });

  testWidgets('the primary button completes the task', (tester) async {
    when(() => taches.obtenirParId('t-1')).thenAnswer((_) async => uneTache());

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // The primary action sits below the fold — scroll it into view first.
    final bouton = find.text('Marquer comme faite');
    await tester.scrollUntilVisible(bouton, 300);
    await tester.tap(bouton);
    await tester.pumpAndSettle();

    final saved =
        verify(() => taches.sauvegarder(captureAny())).captured.last as Tache;
    expect(saved.estFaite, isTrue);
  });
}
