// Widget test for the "Stored data" (data-transparency) section of the Data
// settings panel. Overrides the stats provider with a fixed snapshot.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/state/journal_lignes_illisibles.dart';
import 'package:pot_a_gerer/application/state/statistiques_donnees_notifier.dart';
import 'package:pot_a_gerer/domain/value_objects/statistiques_stockage.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/screens/parametres/panneau_donnees.dart';

void main() {
  Widget app(StatistiquesStockage stats, {JournalLignesIllisibles? journal}) =>
      ProviderScope(
        overrides: [
          statistiquesDonneesProvider.overrideWith((ref) async => stats),
          if (journal != null)
            journalLignesIllisiblesProvider.overrideWithValue(journal),
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

  testWidgets('no unreadable record, no mention', (tester) async {
    final stats = StatistiquesStockage(tables: const [], tailleOctets: 10);
    await tester.pumpWidget(app(stats));
    await tester.pumpAndSettle();
    expect(find.textContaining('illisible'), findsNothing);
  });

  testWidgets('reports the unreadable records kept in the database',
      (tester) async {
    final stats = StatistiquesStockage(tables: const [], tailleOctets: 10);
    final journal = JournalLignesIllisibles()
      ..signaler('taches', 't1', const FormatException('x'))
      ..signaler('plantations', 'p1', const FormatException('x'));
    await tester.pumpWidget(app(stats, journal: journal));
    await tester.pumpAndSettle();
    expect(
        find.text(
            '2 enregistrements illisibles rencontrés, conservés tels quels'),
        findsOneWidget);
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
