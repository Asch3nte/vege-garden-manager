// Widget test for the harvest-recording form.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/recolte.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_recolte_repository.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/forms/formulaire_recolte.dart';

class MockRecoltes extends Mock implements AbstractRecolteRepository {}

class _FakeRecolte extends Fake implements Recolte {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeRecolte()));

  final maintenant = DateTime(2026, 6, 9, 8, 24);
  late MockRecoltes recoltes;

  setUp(() {
    recoltes = MockRecoltes();
    when(() => recoltes.sauvegarder(any())).thenAnswer((_) async {});
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recolteRepositoryProvider.overrideWithValue(recoltes),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FormulaireRecolte(plantationId: 'p-1', plante: 'Tomate'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('persists a harvest for the plantation with defaults',
      (tester) async {
    await monter(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantité'), '2.5');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final recolte =
        verify(() => recoltes.sauvegarder(captureAny())).captured.single
            as Recolte;
    expect(recolte.plantationId, 'p-1');
    expect(recolte.quantite.valeur, 2.5);
    expect(recolte.quantite.unite, UniteQuantite.kg); // default
    expect(recolte.date, maintenant); // default = today
  });

  testWidgets('a non-positive quantity blocks saving', (tester) async {
    await monter(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Quantité'), '0');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Saisis un nombre supérieur à 0.'), findsOneWidget);
    verifyNever(() => recoltes.sauvegarder(any()));
  });
}
