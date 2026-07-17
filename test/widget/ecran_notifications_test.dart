// Widget tests for the notifications (weather-alert) inbox screen.
//
// Overrides [alertesMeteoProvider] directly with a known verdict list (no repos
// needed) and the clock for a deterministic day label.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/state/notifications_notifier.dart';
import 'package:pot_a_gerer/domain/enums/type_alerte_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/alerte_culture.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_notifications.dart';

void main() {
  final maintenant = DateTime(2026, 1, 12, 9);

  Widget app(List<AlerteCulture> alertes) => ProviderScope(
        overrides: [
          horlogeProvider.overrideWithValue(() => maintenant),
          alertesMeteoProvider.overrideWith((ref) async => alertes),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranNotifications(),
        ),
      );

  testWidgets('empty state when there is no active alert', (tester) async {
    await tester.pumpWidget(app(const <AlerteCulture>[]));
    await tester.pumpAndSettle();

    expect(find.text('Aucune alerte'), findsOneWidget);
    expect(
      find.textContaining('ne risquent rien'),
      findsOneWidget,
    );
  });

  testWidgets('renders a frost alert: title, trigger, day and crop count',
      (tester) async {
    final alerte = AlerteCulture(
      type: TypeAlerteMeteo.gel,
      date: DateTime(2026, 1, 12),
      valeurDeclenchante: -2,
      plantationsConcernees: const ['pl-1', 'pl-2'],
    );
    await tester.pumpWidget(app([alerte]));
    await tester.pumpAndSettle();

    expect(find.text('Risque de gel'), findsOneWidget);
    expect(find.text('Minimale prévue : -2 °C'), findsOneWidget);
    // Alert day == pinned "now" → "Aujourd'hui".
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.textContaining('2 cultures en place concernées'), findsOneWidget);
  });
}
