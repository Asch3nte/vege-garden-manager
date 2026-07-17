// Widget test for the "Stored data" (data-transparency) section of the Data
// settings panel. Overrides the stats provider with a fixed snapshot.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/state/statistiques_donnees_notifier.dart';
import 'package:pot_a_gerer/domain/value_objects/statistiques_stockage.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_donnees.dart';

void main() {
  Widget app(StatistiquesStockage stats) => ProviderScope(
        overrides: [
          statistiquesDonneesProvider.overrideWith((ref) async => stats),
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
          home: const PanneauDonnees(),
        ),
      );

  testWidgets('shows the size, total and per-table counts', (tester) async {
    final stats = StatistiquesStockage(
      tables: const [
        StatistiqueTable(nom: 'plantations', lignes: 5),
        StatistiqueTable(nom: 'potagers', lignes: 2),
      ],
      tailleOctets: 1572864, // 1.5 MiB
    );
    await tester.pumpWidget(app(stats));
    await tester.pumpAndSettle();

    expect(find.text('Données stockées'), findsOneWidget);
    expect(find.text('Taille sur l\'appareil'), findsOneWidget);
    expect(find.text('1.5 Mo'), findsOneWidget);
    expect(find.text('7 enregistrements au total'), findsOneWidget);
    // Per-table rows.
    expect(find.text('potagers'), findsOneWidget);
    expect(find.text('plantations'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('formats a byte-range size without decimals', (tester) async {
    final stats = StatistiquesStockage(
      tables: const [StatistiqueTable(nom: 'potagers', lignes: 0)],
      tailleOctets: 512,
    );
    await tester.pumpWidget(app(stats));
    await tester.pumpAndSettle();

    expect(find.text('512 o'), findsOneWidget);
  });
}
