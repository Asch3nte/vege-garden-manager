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
            cultures: const [],
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

  Future<void> monter(WidgetTester tester) async {
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
          home: const FormulaireTache(),
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

  testWidgets('an empty title blocks saving', (tester) async {
    await monter(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    verifyNever(() => taches.sauvegarder(any()));
  });
}
