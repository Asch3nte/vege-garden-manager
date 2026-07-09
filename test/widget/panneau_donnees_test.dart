// Widget test for the data settings panel (Lots A–C): export, import, reset.
//
// The DB↔JSON service and the file/share gestionnaire are both mocked, so these
// tests drive the panel's orchestration (which service runs, with which mode,
// and the confirmation gating) without touching the platform.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/providers/service_providers.dart';
import 'package:pot_a_gerer/domain/entities/preferences_utilisateur.dart';
import 'package:pot_a_gerer/domain/enums/mode_import.dart';
import 'package:pot_a_gerer/domain/exceptions/sauvegarde_invalide_exception.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_inventaire_donnees_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_preferences_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_reinitialisation_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_sauvegarde_service.dart';
import 'package:pot_a_gerer/domain/value_objects/inventaire_donnees.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_donnees.dart';
import 'package:pot_a_gerer/presentation/services/gestionnaire_sauvegarde_fichier.dart';

class _MockReinit extends Mock implements AbstractReinitialisationService {}

class _MockSauvegarde extends Mock implements AbstractSauvegardeService {}

class _MockGestionnaire extends Mock
    implements AbstractGestionnaireSauvegardeFichier {}

class _MockPrefs extends Mock implements AbstractPreferencesRepository {}

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

class _MockInventaire extends Mock implements AbstractInventaireDonneesService {}

void main() {
  setUpAll(() => registerFallbackValue(ModeImport.remplacer));

  late _MockReinit reinit;
  late _MockSauvegarde sauvegarde;
  late _MockGestionnaire gestionnaire;
  late _MockPrefs prefs;
  late _MockPotagers potagers;
  late _MockInventaire inventaire;

  setUp(() {
    reinit = _MockReinit();
    sauvegarde = _MockSauvegarde();
    gestionnaire = _MockGestionnaire();
    prefs = _MockPrefs();
    potagers = _MockPotagers();
    inventaire = _MockInventaire();
    when(() => reinit.reinitialiserTout()).thenAnswer((_) async {});
    when(() => prefs.charger())
        .thenAnswer((_) async => PreferencesUtilisateur());
    when(() => potagers.obtenirTous()).thenAnswer((_) async => []);
    when(() => inventaire.obtenir()).thenAnswer(
      (_) async => InventaireDonnees([
        EntreeInventaire(table: 'potagers', nombre: 2),
        EntreeInventaire(table: 'plantations', nombre: 5),
      ]),
    );
  });

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reinitialisationServiceProvider.overrideWithValue(reinit),
          sauvegardeServiceProvider.overrideWithValue(sauvegarde),
          gestionnaireSauvegardeFichierProvider.overrideWithValue(gestionnaire),
          preferencesRepositoryProvider.overrideWithValue(prefs),
          potagerRepositoryProvider.overrideWithValue(potagers),
          inventaireDonneesServiceProvider.overrideWithValue(inventaire),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PanneauDonnees(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('export', () {
    testWidgets('shares the serialised backup', (tester) async {
      when(() => sauvegarde.exporterJson())
          .thenAnswer((_) async => '{"backup":true}');
      when(() => gestionnaire.partager(any(), any())).thenAnswer((_) async {});

      await monter(tester);
      await tester.tap(find.text('Exporter mes données'));
      await tester.pumpAndSettle();

      final args =
          verify(() => gestionnaire.partager(captureAny(), captureAny()))
              .captured;
      expect(args[0], '{"backup":true}');
      expect(args[1], endsWith('.json'));
    });
  });

  group('transparency', () {
    testWidgets('lists per-table record counts and the total', (tester) async {
      await monter(tester);

      expect(find.text('Transparence des données'), findsOneWidget);
      // Curated labels for the mocked tables, with their counts.
      expect(find.text('Potagers'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Plantations'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      // Total across tables (2 + 5).
      expect(find.text('7 enregistrements au total'), findsOneWidget);
      // The "everything stays local" guarantee is shown.
      expect(
        find.textContaining('jamais transmis'),
        findsOneWidget,
      );
    });
  });

  group('import', () {
    testWidgets('restores the picked file with the chosen mode',
        (tester) async {
      when(() => gestionnaire.choisirEtLire())
          .thenAnswer((_) async => '{"backup":true}');
      when(() => sauvegarde.importerJson(any(), any()))
          .thenAnswer((_) async {});

      await monter(tester);
      await tester.tap(find.text('Importer une sauvegarde'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remplacer tout'));
      await tester.pumpAndSettle();

      verify(() =>
              sauvegarde.importerJson('{"backup":true}', ModeImport.remplacer))
          .called(1);
      expect(find.text('Sauvegarde importée.'), findsOneWidget);
    });

    testWidgets('cancelling the file picker does nothing', (tester) async {
      when(() => gestionnaire.choisirEtLire()).thenAnswer((_) async => null);

      await monter(tester);
      await tester.tap(find.text('Importer une sauvegarde'));
      await tester.pumpAndSettle();

      verifyNever(() => sauvegarde.importerJson(any(), any()));
      expect(find.text('Mode d\'import'), findsNothing);
    });

    testWidgets('an invalid backup surfaces an error', (tester) async {
      when(() => gestionnaire.choisirEtLire())
          .thenAnswer((_) async => 'not a backup');
      when(() => sauvegarde.importerJson(any(), any()))
          .thenThrow(SauvegardeInvalideException('bad'));

      await monter(tester);
      await tester.tap(find.text('Importer une sauvegarde'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fusionner'));
      await tester.pumpAndSettle();

      expect(find.text('Fichier de sauvegarde invalide ou incompatible.'),
          findsOneWidget);
    });
  });

  group('reset', () {
    testWidgets('a full double confirmation runs the reset', (tester) async {
      await monter(tester);

      await tester.tap(find.text('Réinitialiser toutes les données'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tout effacer'));
      await tester.pumpAndSettle();

      verify(() => reinit.reinitialiserTout()).called(1);
    });

    testWidgets('backing out of the first confirmation does nothing',
        (tester) async {
      await monter(tester);

      await tester.tap(find.text('Réinitialiser toutes les données'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(() => reinit.reinitialiserTout());
    });

    testWidgets('stopping at the second confirmation does nothing',
        (tester) async {
      await monter(tester);

      await tester.tap(find.text('Réinitialiser toutes les données'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      verifyNever(() => reinit.reinitialiserTout());
    });
  });
}
