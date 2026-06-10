// Widget test for the hourly weather detail screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/state/meteo_detail_notifier.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_horaire.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_meteo_detail.dart';

void main() {
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  final heures = [
    PrevisionHoraire(
        heure: DateTime(2026, 6, 9, 8), temperature: 21, precipitationsMm: 0),
    PrevisionHoraire(
        heure: DateTime(2026, 6, 9, 14), temperature: 26, precipitationsMm: 0),
    PrevisionHoraire(
        heure: DateTime(2026, 6, 10, 9),
        temperature: 18,
        precipitationsMm: 2,
        probabilitePluie: 0.8),
  ];

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          horlogeProvider.overrideWithValue(() => maintenant),
          meteoHoraireProvider.overrideWith((ref) async => heures),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranMeteoDetail(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the day selector and the selected day hours',
      (tester) async {
    await monter(tester);

    // Day chips for today + tomorrow.
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    // Today is selected by default → its hours/temperatures show.
    expect(find.text('8h'), findsOneWidget);
    expect(find.text('21°'), findsOneWidget);
  });

  testWidgets('switching day shows that day\'s hours', (tester) async {
    await monter(tester);

    expect(find.text('18°'), findsNothing); // tomorrow not shown yet
    await tester.tap(find.text('Demain'));
    await tester.pumpAndSettle();

    expect(find.text('9h'), findsOneWidget);
    expect(find.text('18°'), findsOneWidget);
  });
}
