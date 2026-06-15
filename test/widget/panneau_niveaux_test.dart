// Widget test for the experience-levels guide (ADR-0009 §4a mini-tuto).
//
// Checks the catalogue renders the why/how content and marks features as
// "unlocked" according to the user's level (and as a teaser otherwise).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_niveaux.dart';

void main() {
  Future<void> monter(WidgetTester tester, NiveauExperience niveau) async {
    // Tall surface so every feature card is laid out (the panel scrolls).
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accesNiveauProvider.overrideWithValue(AccesNiveau(niveau)),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PanneauNiveaux(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists features with their why/how content', (tester) async {
    await monter(tester, NiveauExperience.intermediaire);

    expect(find.text('Vue Réseau du Catalogue'), findsOneWidget);
    expect(find.text('Sol : texture & pH'), findsOneWidget);
    // The why/how labels are rendered (inside RichText spans).
    expect(find.textContaining('Pourquoi', findRichText: true), findsWidgets);
    expect(find.textContaining('Comment', findRichText: true), findsWidgets);
  });

  testWidgets('a beginner sees everything as a teaser (no unlocked badge)',
      (tester) async {
    await monter(tester, NiveauExperience.debutant);

    expect(find.text('Débloqué'), findsNothing);
  });

  testWidgets('intermediate unlocks the intermediate tier only', (tester) async {
    await monter(tester, NiveauExperience.intermediaire);

    // 6 intermediate features are unlocked; the 2 expert ones are not.
    expect(find.text('Débloqué'), findsNWidgets(6));
  });

  testWidgets('expert unlocks every listed feature', (tester) async {
    await monter(tester, NiveauExperience.expert);

    expect(find.text('Débloqué'), findsNWidgets(8));
  });
}
