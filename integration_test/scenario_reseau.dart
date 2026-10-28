import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pot_a_gerer/infrastructure/database/app_database.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';

import '../test/helpers/garde_reseau.dart';
import '../test/helpers/potager_actif.dart';
import 'support/lancer_app.dart';

Future<void> _taper(WidgetTester tester, String libelle) =>
    taper(tester, libelle, (t) => t.pumpAndSettle());

Future<BuildContext> _lancer(
  WidgetTester tester, {
  required bool meteoAuto,
}) async {
  fixerVueLarge(tester);

  final base = AppDatabase(NativeDatabase.memory());
  await peuplerPotagerActif(base, meteoAuto: meteoAuto, position: bruxelles);
  await lancerApp(tester, base: base);
  return tester.element(find.byType(Navigator).first);
}

/// Registers this scenario's tests.
void scenarioReseau() {
  testWidgets('weather auto off: no request from the real app', (tester) async {
    final garde = GardeReseau.installer();
    final context = await _lancer(tester, meteoAuto: false);
    final l10n = AppLocalizations.of(context)!;

    await _taper(tester, l10n.navCalendrier);
    await _taper(tester, l10n.navPotager);
    await _taper(tester, l10n.navAccueil);
    await tester.pump(const Duration(seconds: 5));

    expect(garde.requetes, isEmpty);
  });

  testWidgets('weather screen: only allowed hosts are contacted', (
    tester,
  ) async {
    final garde = GardeReseau.installer();
    final context = await _lancer(tester, meteoAuto: true);

    GoRouter.of(context).go('/accueil/meteo');
    for (var i = 0; i < 50 && garde.requetes.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(garde.hotes, contains('api.open-meteo.com'));
    expect(garde.hotes.difference(hotesAutorises), isEmpty);
  });
}
