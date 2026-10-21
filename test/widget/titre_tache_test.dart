import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/state/nom_plante_plantation_provider.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/titre_tache.dart';

void main() {
  Tache tache({String? titre}) => Tache(
        id: 't-1',
        titre: titre,
        generee: titre == null,
        type: TypeTache.arrosage,
        cible: CibleTache.plantation,
        cibleId: 'pl-1',
        datePrevue: DateTime(2026, 6, 9),
      );

  Future<void> monter(WidgetTester tester, Tache t, Locale locale) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        nomPlantePlantationProvider('pl-1').overrideWith(
            (ref) async => locale.languageCode == 'en' ? 'Tomato' : 'Tomate'),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TitreTache(t)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('own title is shown as is', (tester) async {
    await monter(tester, tache(titre: 'Arroser au purin'), const Locale('en'));
    expect(find.text('Arroser au purin'), findsOneWidget);
  });

  testWidgets('derived title in French', (tester) async {
    await monter(tester, tache(), const Locale('fr'));
    expect(find.text('Arroser : Tomate'), findsOneWidget);
  });

  testWidgets('derived title in English', (tester) async {
    await monter(tester, tache(), const Locale('en'));
    expect(find.text('Water: Tomato'), findsOneWidget);
  });
}
