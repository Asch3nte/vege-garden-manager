// Widget tests for the Calendrier agenda screen.
//
// Overrides the task repository + clock, then checks the day grouping, the
// relative day labels, ticking a task and the empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/app/theme/theme_app.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/acces_niveau_provider.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/etat_tache.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/application/state/saison_notifier.dart';
import 'package:pot_a_gerer/application/state/saison_vue.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/application/use_cases/generer_taches_arrosage.dart';
import 'package:pot_a_gerer/presentation/screens/ecran_calendrier.dart';

class MockTaches extends Mock implements AbstractTacheRepository {}

/// No-op stub: watering task generation is tested separately.
class _StubGenererTachesArrosage implements GenererTachesArrosage {
  @override
  Future<void> executer() async {}
}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class _FakeTache extends Fake implements Tache {}

/// A fixed season view so the Saison tab can render without the garden repos.
class _FakeSaison extends SaisonNotifier {
  @override
  Future<SaisonVue> build() async => SaisonVue(
        hemisphereSuppose: true,
        lignes: [
          LigneSaison(
            nom: 'Tomate',
            semis: const Periode(3, 5),
            plantation: const Periode(4, 5),
            recolte: const Periode(7, 9),
          ),
        ],
      );
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeTache()));

  final maintenant = DateTime(2026, 6, 8, 8, 24); // Monday 8 June 2026

  late MockTaches taches;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockPotagers potagers;
  late MockFiches fiches;

  setUp(() {
    taches = MockTaches();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    potagers = MockPotagers();
    fiches = MockFiches();
    when(() => plantations.obtenirParId(any())).thenAnswer((_) async => null);
    when(() => fiches.obtenirParId(any())).thenAnswer((_) async => null);
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);
    // The zone 'z-1' used by the sample tasks resolves to a named bed.
    when(() => parcelles.obtenirParId('z-1')).thenAnswer(
      (_) async => Parcelle(
        id: 'z-1',
        nom: 'Carré nord',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      ),
    );
    when(() => parcelles.obtenirParId(any(that: isNot('z-1'))))
        .thenAnswer((_) async => null);
  });

  /// Repository overrides shared by every mounted scope so the calendar's
  /// target-name resolution has its repos.
  reposOverrides() => [
        tacheRepositoryProvider.overrideWithValue(taches),
        parcelleRepositoryProvider.overrideWithValue(parcelles),
        plantationRepositoryProvider.overrideWithValue(plantations),
        potagerRepositoryProvider.overrideWithValue(potagers),
        fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
        horlogeProvider.overrideWithValue(() => maintenant),
        genererTachesArrosageProvider
            .overrideWith((ref) async => _StubGenererTachesArrosage()),
      ];

  Tache uneTache(String id, String titre, DateTime quand,
          {bool faite = false, TypeTache type = TypeTache.arrosage}) =>
      Tache(
        id: id,
        titre: titre,
        type: type,
        cible: CibleTache.parcelle,
        cibleId: 'z-1',
        datePrevue: quand,
        etat: faite ? EtatTache.terminee : EtatTache.aFaire,
        dateRealisation: faite ? quand : null,
      );

  /// Number of coloured dots drawn in the month grid cell of day [jour].
  ///
  /// The cell is the `InkWell` holding the day number; a dot is a 6×6 circular
  /// [Container] inside it.
  int pastillesDuJour(WidgetTester tester, String jour) {
    final cellule = find
        .ancestor(of: find.text(jour), matching: find.byType(InkWell))
        .first;
    return tester
        .widgetList<Container>(
          find.descendant(of: cellule, matching: find.byType(Container)),
        )
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.shape == BoxShape.circle;
        })
        .length;
  }

  Future<void> monter(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...reposOverrides(),
          // Intermediate so the level-up teaser (shown to beginners) doesn't
          // take space; these tests exercise the calendar views, not the teaser.
          accesNiveauProvider.overrideWithValue(
              const AccesNiveau(NiveauExperience.intermediaire)),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranCalendrier(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('groups tasks under relative day headers', (tester) async {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('t1', 'Arroser les tomates', DateTime(2026, 6, 8, 10)),
        uneTache('t2', 'Tuteurer les haricots', DateTime(2026, 6, 9, 10)),
      ],
    );

    await monter(tester);

    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    expect(find.text('Arroser les tomates'), findsOneWidget);
    expect(find.text('Tuteurer les haricots'), findsOneWidget);
    // Each card resolves its target (zone 'z-1') to its real name.
    expect(find.text('Carré nord'), findsNWidgets(2));
  });

  testWidgets('tapping a task ticks it off (persisted)', (tester) async {
    final tache = uneTache('t1', 'Arroser les tomates', DateTime(2026, 6, 8, 10));
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await monter(tester);
    await tester.tap(find.text('Arroser les tomates'));
    await tester.pumpAndSettle();

    expect(tache.estFaite, isTrue);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  testWidgets('tapping a done task unchecks it (persisted)', (tester) async {
    final tache = uneTache('t1', 'Arroser les tomates', DateTime(2026, 6, 8, 10),
        faite: true);
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await monter(tester);
    await tester.tap(find.text('Arroser les tomates'));
    await tester.pumpAndSettle();

    expect(tache.estFaite, isFalse);
    verify(() => taches.sauvegarder(tache)).called(1);
  });

  testWidgets('the overflow menu deletes a task after confirmation',
      (tester) async {
    final tache = uneTache('t1', 'Arroser les tomates', DateTime(2026, 6, 8, 10));
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [tache]);
    when(() => taches.supprimer(any())).thenAnswer((_) async {});

    await monter(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer')); // menu item
    await tester.pumpAndSettle();

    // Confirmation dialog.
    expect(find.text('Supprimer cette tâche ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    verify(() => taches.supprimer('t1')).called(1);
  });

  testWidgets('empty window shows the empty state', (tester) async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    await monter(tester);

    expect(find.text('Rien de prévu — profitez du jardin.'), findsOneWidget);
  });

  testWidgets('the month view shows the grid and the selected day tasks',
      (tester) async {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async =>
          [uneTache('t1', 'Arroser les tomates', DateTime(2026, 6, 8, 10))],
    );

    await monter(tester);

    // Switch from Agenda to the month grid.
    await tester.tap(find.text('Mois'));
    await tester.pumpAndSettle();

    expect(find.text('Lun'), findsOneWidget); // weekday header
    expect(find.text('Juin 2026'), findsOneWidget); // month title
    // Today (8 June) is selected by default → its task is listed below.
    expect(find.text('Arroser les tomates'), findsOneWidget);

    // Selecting an empty day shows the empty state.
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('Arroser les tomates'), findsNothing);
    expect(find.text('Rien de prévu — profitez du jardin.'), findsOneWidget);
  });

  testWidgets('a month day shows one dot per gesture type, not per task',
      (tester) async {
    // Regression: a day watering several crops used to draw one dot per task.
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        for (var i = 0; i < 5; i++)
          uneTache('eau$i', 'Arroser $i', DateTime(2026, 6, 9, 8 + i)),
      ],
    );

    await monter(tester);
    await tester.tap(find.text('Mois'));
    await tester.pumpAndSettle();

    expect(pastillesDuJour(tester, '9'), 1); // 5 watering tasks → a single dot
  });

  testWidgets('a month day with mixed gestures shows one dot per type',
      (tester) async {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('eau1', 'Arroser', DateTime(2026, 6, 9, 8)),
        uneTache('eau2', 'Arroser encore', DateTime(2026, 6, 9, 9)),
        uneTache('semis', 'Semer', DateTime(2026, 6, 9, 14),
            type: TypeTache.semis),
      ],
    );

    await monter(tester);
    await tester.tap(find.text('Mois'));
    await tester.pumpAndSettle();

    expect(pastillesDuJour(tester, '9'), 2); // arrosage + semis
  });

  testWidgets('the season view charts the cultivated plants', (tester) async {
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...reposOverrides(),
          saisonProvider.overrideWith(_FakeSaison.new),
          // Saison view is intermediate+ (ADR-0009).
          accesNiveauProvider.overrideWithValue(
              const AccesNiveau(NiveauExperience.intermediaire)),
        ],
        child: MaterialApp(
          theme: ThemeApp.clair(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const EcranCalendrier(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saison'));
    await tester.pumpAndSettle();

    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Semis'), findsWidgets); // band label + legend
    expect(find.textContaining('Hémisphère nord supposé'), findsOneWidget);
  });

  /// Three watering tasks + one sowing task, all planned today (8 June).
  void plusieursTaches() {
    when(() => taches.obtenirEntreDates(any(), any())).thenAnswer(
      (_) async => [
        uneTache('t-1', 'Arroser les tomates', DateTime(2026, 6, 8, 8)),
        uneTache('t-2', 'Arroser les courgettes', DateTime(2026, 6, 8, 9)),
        uneTache('t-3', 'Arroser le basilic', DateTime(2026, 6, 8, 10)),
        uneTache('t-4', 'Semer les radis', DateTime(2026, 6, 8, 14),
            type: TypeTache.semis),
      ],
    );
  }

  testWidgets('same-gesture tasks collapse into one agenda card',
      (tester) async {
    plusieursTaches();

    await monter(tester);

    expect(find.text('Arroser les tomates'), findsNothing);
    expect(find.textContaining('3 tâches'), findsOneWidget);
    // A lone task keeps its ordinary card, title and all.
    expect(find.text('Semer les radis'), findsOneWidget);
  });

  testWidgets('expanding an agenda group lists its targets', (tester) async {
    plusieursTaches();

    await monter(tester);
    await tester.tap(find.textContaining('3 tâches'));
    await tester.pumpAndSettle();

    // Subtask rows show the resolved target, falling back to the title: 3 for
    // the expanded watering group + 1 on the lone sowing card.
    expect(find.text('Carré nord'), findsNWidgets(4));
  });

  testWidgets('the agenda group check button completes every task at once',
      (tester) async {
    plusieursTaches();
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await monter(tester);
    await tester.tap(find.byTooltip('Tout marquer comme fait'));
    await tester.pumpAndSettle();

    final captured = verify(() => taches.sauvegarder(captureAny())).captured;
    expect(captured, hasLength(3));
    expect(captured.map((t) => (t as Tache).id), ['t-1', 't-2', 't-3']);
    expect(captured.map((t) => (t as Tache).estFaite), everyElement(isTrue));
  });

  testWidgets('a subtask can be ticked without the rest of its group',
      (tester) async {
    plusieursTaches();
    when(() => taches.sauvegarder(any())).thenAnswer((_) async {});

    await monter(tester);
    await tester.tap(find.textContaining('3 tâches'));
    await tester.pumpAndSettle();
    // Second subtask row = 'Arroser les courgettes' (t-2), ordered by time.
    await tester.tap(find.text('Carré nord').at(1));
    await tester.pumpAndSettle();

    final captured = verify(() => taches.sauvegarder(captureAny())).captured;
    expect(captured, hasLength(1));
    expect((captured.single as Tache).id, 't-2');
  });

  testWidgets('the month view groups the selected day the same way',
      (tester) async {
    plusieursTaches();

    await monter(tester);
    await tester.tap(find.text('Mois'));
    await tester.pumpAndSettle();

    expect(find.textContaining('3 tâches'), findsOneWidget);
    expect(find.text('Arroser les tomates'), findsNothing);
  });
}
