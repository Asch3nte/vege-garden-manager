import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/main.dart';

import '../../helpers/faux_services_natifs.dart';
import '../../helpers/garde_reseau.dart';
import '../../helpers/potager_actif.dart';

/// Launches the whole app on a seeded in-memory database, wired with the real
/// weather and geocoding services.
Future<AppDatabase> _lancer(
  WidgetTester tester, {
  required bool meteoAuto,
  required Localisation position,
}) async {
  fixerVueLarge(tester);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.runAsync(
    () => peuplerPotagerActif(db, meteoAuto: meteoAuto, position: position),
  );
  await tester.pumpWidget(
    ProviderScope(overrides: surchargesDeTest(db), child: const PotAGererApp()),
  );
  await _stabiliser(tester);
  return db;
}

/// Lets real I/O (database, assets) complete between frames, then settles.
Future<void> _stabiliser(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Navigator).first))!;

Future<void> _taper(WidgetTester tester, String libelle) =>
    taper(tester, libelle, _stabiliser);

void main() {
  testWidgets('only allowed hosts are ever contacted', (tester) {
    return avecGardeReseau((garde) async {
      await _lancer(tester, meteoAuto: true, position: bruxelles);
      final l10n = _l10n(tester);
      final routeur = GoRouter.of(tester.element(find.byType(Navigator).first));

      routeur.go('/accueil/meteo');
      await _stabiliser(tester);
      routeur.go('/accueil');
      await _stabiliser(tester);

      await _taper(tester, l10n.navPotager);
      await tester.tap(
        find.byWidgetPredicate((w) => w is PopupMenuButton).first,
      );
      await _stabiliser(tester);
      await _taper(tester, l10n.potagerModifier);
      await _taper(tester, l10n.captureCarteChoisir);
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == l10n.carteMondeRechercheIndice,
        ),
        'Bruxelles',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _stabiliser(tester);
      await tester.pump(const Duration(hours: 1));

      expect(garde.hotes, hotesAutorises);
    });
  });

  testWidgets('weather auto off: no automatic request', (tester) {
    return avecGardeReseau((garde) async {
      await _lancer(tester, meteoAuto: false, position: bruxelles);
      final l10n = _l10n(tester);

      for (final onglet in [l10n.navCalendrier, l10n.navPotager]) {
        await _taper(tester, onglet);
      }
      await _taper(tester, l10n.navAccueil);
      await tester.pump(const Duration(hours: 1));

      expect(garde.requetes, isEmpty);
    });
  });

  testWidgets('location disabled: no automatic geocoding', (tester) {
    return avecGardeReseau((garde) async {
      await _lancer(
        tester,
        meteoAuto: true,
        position: const Localisation.nonDefinie(),
      );
      final l10n = _l10n(tester);

      for (final onglet in [l10n.navCalendrier, l10n.navPotager]) {
        await _taper(tester, onglet);
      }
      await _taper(tester, l10n.navAccueil);
      GoRouter.of(
        tester.element(find.byType(Navigator).first),
      ).go('/accueil/meteo');
      await _stabiliser(tester);
      await tester.pump(const Duration(hours: 1));

      expect(garde.requetes, isEmpty);
    });
  });

  testWidgets('user-triggered weather screen may call open-meteo', (tester) {
    return avecGardeReseau((garde) async {
      await _lancer(tester, meteoAuto: true, position: bruxelles);
      GoRouter.of(
        tester.element(find.byType(Navigator).first),
      ).go('/accueil/meteo');
      await _stabiliser(tester);

      expect(garde.hotes, contains('api.open-meteo.com'));
      expect(garde.hotes.difference(hotesAutorises), isEmpty);
    });
  });
}
