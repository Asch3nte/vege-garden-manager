import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_donnees.dart';
import 'package:pot_a_gerer/presentation/services/gestionnaire_sauvegarde_fichier.dart';

import '../helpers/faux_services_natifs.dart';
import '../helpers/jeu_donnees_riche.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<AppLocalizations> monter(
    WidgetTester tester,
    AbstractGestionnaireSauvegardeFichier fichiers,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...surchargesDeTest(
            db,
          ).where((o) => o.origin != gestionnaireSauvegardeFichierProvider),
          gestionnaireSauvegardeFichierProvider.overrideWithValue(fichiers),
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
    return AppLocalizations.of(tester.element(find.byType(PanneauDonnees)))!;
  }

  testWidgets('non-UTF-8 file shows the import error and keeps the data', (
    tester,
  ) async {
    await peuplerJeuRiche(db);
    final avant = await instantane(db);
    final l10n = await monter(
      tester,
      GestionnaireSauvegardeFichier(
        lireFichierChoisi: () async => [0xff, 0xfe, 0x00],
      ),
    );

    await tester.tap(find.text(l10n.donneesImportBouton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.donneesImportErreur), findsOneWidget);
    expect(find.text(l10n.donneesImportSucces), findsNothing);
    expect(tester.takeException(), isNull);
    expect(await instantane(db), equals(avant));
  });

  testWidgets('invalid JSON shows the import error and keeps the data', (
    tester,
  ) async {
    await peuplerJeuRiche(db);
    final avant = await instantane(db);
    final l10n = await monter(
      tester,
      FauxGestionnaireSauvegardeFichier()..aLire = '{"schemaVersion": 1, "tab',
    );

    await tester.tap(find.text(l10n.donneesImportBouton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.donneesImportModeRemplacer));
    await tester.pumpAndSettle();

    expect(find.text(l10n.donneesImportErreur), findsOneWidget);
    expect(find.text(l10n.donneesImportSucces), findsNothing);
    expect(tester.takeException(), isNull);
    expect(await instantane(db), equals(avant));
  });
}
