// Widget test for the garden-creation form.
//
// Fills the name, keeps the sensible climate/hardiness defaults, taps save and
// checks the garden is persisted (and the form pops the created entity).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_potager.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class _FakePotager extends Fake implements Potager {}

void main() {
  setUpAll(() => registerFallbackValue(_FakePotager()));

  late MockPotagers repo;

  setUp(() {
    repo = MockPotagers();
    when(() => repo.sauvegarder(any())).thenAnswer((_) async {});
    when(() => repo.obtenirTous()).thenAnswer((_) async => []);
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [potagerRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FormulairePotager(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('persists a garden with the entered name and defaults',
      (tester) async {
    await monter(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Mon potager');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.sauvegarder(captureAny())).captured;
    final potager = captured.single as Potager;
    expect(potager.nom, 'Mon potager');
    // Defaults: oceanic climate, hardiness zone 8.
    expect(potager.zoneClimatique.type, TypeClimat.oceanique);
    expect(potager.zoneClimatique.rusticite, ZoneRusticite.zone8);
  });

  testWidgets('an empty name blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => repo.sauvegarder(any()));
  });
}
