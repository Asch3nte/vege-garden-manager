import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/sens_swipe_provider.dart';
import 'package:pot_a_gerer/application/state/suppressions_differees_notifier.dart';
import 'package:pot_a_gerer/domain/enums/sens_swipe.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/presentation/widgets/element_balayable.dart';
import 'package:pot_a_gerer/presentation/widgets/tache_balayable.dart';

void main() {
  late List<String> appels;
  late bool quitte;
  late bool echoue;

  setUp(() {
    appels = [];
    quitte = false;
    echoue = false;
  });

  Future<void> monter(
    WidgetTester tester, {
    SensSwipe sens = SensSwipe.standard,
    bool archivable = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sensSwipeProvider.overrideWithValue(sens)],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                ElementBalayable(
                  cle: 'a',
                  libelleArchiver: 'Marquer faite',
                  surArchiver: archivable
                      ? () async {
                          appels.add('archiver');
                          return quitte;
                        }
                      : null,
                  surSupprimer: () async {
                    appels.add('supprimer');
                    if (echoue) throw Exception('disque plein');
                    return quitte;
                  },
                  child: const ListTile(title: Text('Arroser')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> balayer(WidgetTester tester, double dx) async {
    await tester.drag(find.text('Arroser'), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('standard: leftwards deletes, rightwards archives',
      (tester) async {
    await monter(tester);
    await balayer(tester, -500);
    await balayer(tester, 500);
    expect(appels, ['supprimer', 'archiver']);
  });

  testWidgets('inverse swaps the two directions', (tester) async {
    await monter(tester, sens: SensSwipe.inverse);
    await balayer(tester, -500);
    await balayer(tester, 500);
    expect(appels, ['archiver', 'supprimer']);
  });

  testWidgets('an item that stays in its list comes back', (tester) async {
    await monter(tester);
    await balayer(tester, -500);
    expect(find.text('Arroser'), findsOneWidget);
  });

  testWidgets('an item that leaves its list disappears', (tester) async {
    quitte = true;
    await monter(tester);
    await balayer(tester, -500);
    expect(find.text('Arroser'), findsNothing);
  });

  testWidgets('the next item stays visible once the list drops the first',
      (tester) async {
    var elements = ['Arroser', 'Pailler'];
    late StateSetter majListe;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(builder: (context, setState) {
              majListe = setState;
              return ListView(children: [
                for (final e in elements)
                  ElementBalayable(
                    cle: e,
                    surSupprimer: () async => true,
                    child: ListTile(title: Text(e)),
                  ),
              ]);
            }),
          ),
        ),
      ),
    );

    await balayer(tester, -500);
    majListe(() => elements = ['Pailler']);
    await tester.pumpAndSettle();

    expect(find.text('Pailler'), findsOneWidget);
  });

  testWidgets('a failed action is reported and the item comes back',
      (tester) async {
    echoue = true;
    await monter(tester);
    await balayer(tester, -500);

    expect(find.text('Arroser'), findsOneWidget);
    expect(find.text('Enregistrement impossible. Réessayez.'), findsOneWidget);
  });

  testWidgets('a done task shows the reopening icon', (tester) async {
    final tache = Tache(
      id: 't-1',
      titre: 'Arroser',
      type: TypeTache.arrosage,
      cible: CibleTache.potager,
      cibleId: 'pot-1',
      datePrevue: DateTime(2026, 6, 1),
    )..marquerFaite(DateTime(2026, 6, 1));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TacheBalayable(
              tache: tache,
              onBasculer: () {},
              onSupprimer: () async => false,
              child: const ListTile(title: Text('Arroser')),
            ),
          ),
        ),
      ),
    );
    final geste =
        await tester.startGesture(tester.getCenter(find.text('Arroser')));
    await geste.moveBy(const Offset(20, 0));
    await geste.moveBy(const Offset(180, 0));
    await tester.pump();

    expect(find.byIcon(PhosphorIconsBold.arrowCounterClockwise), findsOneWidget);
    await geste.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a short swipe triggers nothing', (tester) async {
    await monter(tester);
    await balayer(tester, -40);
    expect(appels, isEmpty);
  });

  testWidgets('a side without action does not swipe', (tester) async {
    await monter(tester, archivable: false);
    await balayer(tester, 500);
    expect(appels, isEmpty);
  });

  testWidgets('the revealed side shows its action icon', (tester) async {
    await monter(tester);
    final geste = await tester.startGesture(tester.getCenter(find.text('Arroser')));
    // A first move past the drag slop starts the swipe.
    await geste.moveBy(const Offset(-20, 0));
    await geste.moveBy(const Offset(-180, 0));
    await tester.pump();
    expect(find.byIcon(PhosphorIconsBold.x), findsOneWidget);
    await geste.moveBy(const Offset(400, 0));
    await tester.pump();
    expect(find.byIcon(PhosphorIconsBold.archive), findsOneWidget);
    await geste.up();
    await tester.pumpAndSettle();
  });

  testWidgets('screen readers get both actions', (tester) async {
    final semantique = tester.ensureSemantics();
    await monter(tester);
    final noeud = tester.getSemantics(find.text('Arroser'));
    final libelles = noeud.getSemanticsData().customSemanticsActionIds;
    expect(libelles, hasLength(2));
    semantique.dispose();
  });

  group('pending deletion', () {
    SuppressionsDiffereesNotifier suppressions(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(ListView)))
            .read(suppressionsDiffereesProvider.notifier);

    testWidgets('hides the item, which comes back once cancelled',
        (tester) async {
      await monter(tester);

      suppressions(tester).programmer('a', (_) async {});
      await tester.pump();
      expect(find.text('Arroser'), findsNothing);

      suppressions(tester).annuler('a');
      await tester.pump();
      expect(find.text('Arroser'), findsOneWidget);
    });

    testWidgets('a swiped-away item comes back once cancelled',
        (tester) async {
      quitte = true;
      await monter(tester);
      await balayer(tester, -500);
      suppressions(tester).programmer('a', (_) async {});
      await tester.pump();
      expect(find.text('Arroser'), findsNothing);

      suppressions(tester).annuler('a');
      await tester.pumpAndSettle();
      expect(find.text('Arroser'), findsOneWidget);
    });
  });
}
