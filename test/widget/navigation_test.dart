// Widget tests for the primary navigation shell.
//
// Exercises [PotAGererApp] directly (not [main]), so it needs no platform
// bootstrap (database, timezone, notifications). It checks the app mounts on the
// Accueil tab, that the layout is responsive (bottom bar vs rail around the
// 600px breakpoint), and that selecting a destination switches the screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pot_a_gerer/main.dart';

void main() {
  // Pumps the app at a given logical size so we control which responsive branch
  // (bottom NavigationBar < 600px, NavigationRail ≥ 600px) is exercised.
  Future<void> pomperA(WidgetTester tester, Size taille) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PotAGererApp());
    await tester.pumpAndSettle();
  }

  testWidgets('mobile width shows a bottom bar with the five destinations',
      (tester) async {
    await pomperA(tester, const Size(390, 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final libelle in const [
      'Accueil',
      'Potager',
      'Catalogue',
      'Calendrier',
      'Plus',
    ]) {
      expect(find.text(libelle), findsWidgets, reason: 'onglet $libelle');
    }

    // Accueil is the initial branch.
    expect(find.widgetWithText(AppBar, 'Accueil'), findsOneWidget);
  });

  testWidgets('tablet width shows a rail instead of the bottom bar',
      (tester) async {
    await pomperA(tester, const Size(900, 700));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('selecting a destination switches the active screen',
      (tester) async {
    await pomperA(tester, const Size(390, 800));

    // Tap the "Catalogue" label in the bottom bar.
    await tester.tap(find.text('Catalogue'));
    await tester.pumpAndSettle();

    // The Catalogue screen's app bar is now shown…
    expect(find.widgetWithText(AppBar, 'Catalogue'), findsOneWidget);
    // …and the Accueil app bar is no longer the visible one.
    expect(find.widgetWithText(AppBar, 'Accueil'), findsNothing);
  });
}
