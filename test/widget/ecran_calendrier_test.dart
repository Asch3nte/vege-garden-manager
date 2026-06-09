// Widget tests for the Calendrier agenda screen.
//
// Overrides the task repository + clock, then checks the day grouping, the
// relative day labels, ticking a task and the empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_calendrier.dart';

class MockTaches extends Mock implements AbstractTacheRepository {}

class _FakeTache extends Fake implements Tache {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  final maintenant = DateTime(2026, 6, 8, 8, 24); // Monday 8 June 2026

  late MockTaches taches;

  setUp(() => taches = MockTaches());

  Tache uneTache(String id, String titre, DateTime quand) => Tache(
        id: id,
        titre: titre,
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: quand,
      );

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tacheRepositoryProvider.overrideWithValue(taches),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranCalendrier(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('groups tasks under relative day headers', (tester) async {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('t1', 'Arroser les tomates', DateTime(2026, 6, 8, 10)),
        uneTache('t2', 'Tuteurer les haricots', DateTime(2026, 6, 9, 10)),
      ],
    );

    await monter(tester);

    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    expect(find.text('Arroser les tomates'), findsOneWidget);
    expect(find.text('Tuteurer les haricots'), findsOneWidget);
  });

  testWidgets('tapping a task ticks it off (persisted)', (tester) async {
    final tache = uneTache('t1', 'Arroser les tomates', DateTime(2026, 6, 8, 10));
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await monter(tester);
    await tester.tap(find.text('Arroser les tomates'));
    await tester.pumpAndSettle();

    expect(tache.estFaite, isTrue);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  testWidgets('empty window shows the empty state', (tester) async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    await monter(tester);

    expect(find.text('Rien de prévu — profitez du jardin.'), findsOneWidget);
  });
}
