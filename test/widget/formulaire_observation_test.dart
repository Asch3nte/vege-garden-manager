// Widget test for the observation-recording form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/observation.dart';
import 'package:pot_a_gerer/domain/enums/cible_observation.dart';
import 'package:pot_a_gerer/domain/enums/type_observation.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_observation_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_observation.dart';

class MockObservations extends Mock implements AbstractObservationRepository {}

class _FakeObservation extends Fake implements Observation {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeObservation()));

  final maintenant = DateTime(2026, 6, 9, 8, 24);
  late MockObservations observations;

  setUp(() {
    observations = MockObservations();
    when(() => observations.sauvegarder(any())).thenAnswer((_) async {});
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          observationRepositoryProvider.overrideWithValue(observations),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home:
              const FormulaireObservation(plantationId: 'p-1', plante: 'Tomate'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('persists an observation on the plantation', (tester) async {
    await monter(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Titre'), 'Feuilles jaunies');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final obs = verify(() => observations.sauvegarder(captureAny()))
        .captured
        .single as Observation;
    expect(obs.titre, 'Feuilles jaunies');
    expect(obs.cible, CibleObservation.plantation);
    expect(obs.cibleId, 'p-1');
    expect(obs.type, TypeObservation.general); // default
    expect(obs.date, maintenant);
  });

  testWidgets('an empty title blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => observations.sauvegarder(any()));
  });
}
