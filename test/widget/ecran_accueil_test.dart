// Widget tests for the Accueil dashboard screen.
//
// Overrides the four repositories + the clock so the screen renders a known
// view-model, then checks the rendered sections and the progressive-disclosure
// rule (season stats unlock at expert level).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_accueil.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

class MockPreferences extends Mock implements AbstractPreferencesRepository {}

void main() {
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockTaches taches;
  late MockPreferences preferences;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    taches = MockTaches();
    preferences = MockPreferences();

    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      ),
    );
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        Parcelle(
          id: 'z-1',
          nom: 'Carré nord',
          potagerId: 'pot-1',
          type: TypeParcelle.bacSureleve,
          surface: Surface.enMetresCarres(1),
          exposition: NiveauSoleil.pleinSoleil,
        ),
      ],
    );
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        Tache(
          id: 't-1',
          titre: 'Arroser les tomates',
          type: TypeTache.arrosage,
          cible: CibleTache.parcelle,
          cibleId: 'z-1',
          datePrevue: maintenant,
        ),
      ],
    );
  });

  Future<void> monter(WidgetTester tester, NiveauExperience niveau) async {
    when(() => preferences.charger()).thenAnswer(
      (_) async => PreferencesUtilisateur(niveauExperience: niveau),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          tacheRepositoryProvider.overrideWithValue(taches),
          preferencesRepositoryProvider.overrideWithValue(preferences),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders today\'s tasks and the garden overview', (tester) async {
    await monter(tester, NiveauExperience.intermediaire);

    expect(find.text('Tâches du jour'), findsOneWidget);
    expect(find.text('Arroser les tomates'), findsOneWidget);
    expect(find.text('Aperçu du potager'), findsOneWidget);
    expect(find.text('Carré nord'), findsOneWidget);
  });

  testWidgets('season stats stay locked below expert level', (tester) async {
    await monter(tester, NiveauExperience.intermediaire);

    expect(find.text('Statistiques au niveau Expert'), findsOneWidget);
    expect(find.text('Récoltes de la saison à venir'), findsNothing);
  });

  testWidgets('season stats unlock at expert level', (tester) async {
    await monter(tester, NiveauExperience.expert);

    expect(find.text('Récoltes de la saison à venir'), findsOneWidget);
    expect(find.text('Statistiques au niveau Expert'), findsNothing);
  });

  testWidgets('error state offers a retry', (tester) async {
    when(() => preferences.charger()).thenThrow(Exception('boom'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          potagerRepositoryProvider.overrideWithValue(potagers),
          parcelleRepositoryProvider.overrideWithValue(parcelles),
          tacheRepositoryProvider.overrideWithValue(taches),
          preferencesRepositoryProvider.overrideWithValue(preferences),
          horlogeProvider.overrideWithValue(() => maintenant),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranAccueil(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réessayer'), findsOneWidget);
  });
}
