// Characterization tests for [VueReseauCatalogue] — the catalogue "Réseau" view.
//
// Written as a safety net BEFORE the lot E rework (docs/15 §8 E): they pin the
// current behaviour (nodes, selection → panel, re-tap → sheet, "à éviter"
// toggle) so the upcoming zoom/pan/fit changes can't regress it silently.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_famille_botanique_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/vue_reseau_catalogue.dart';

class _MockFiches extends Mock implements AbstractFichePlanteRepository {}

class _MockFamilles extends Mock
    implements AbstractFamilleBotaniqueRepository {}

class _MockPotagers extends Mock implements AbstractPotagerRepository {}

FichePlante _fiche(
  String id,
  String nomFr,
  CategoriePlante cat, {
  Set<String> bons = const {},
  Set<String> mauvais = const {},
  String famille = 'Test',
}) => FichePlante(
  id: id,
  nomScientifique: '$id sp',
  familleBotanique: famille,
  categorie: cat,
  usages: const {UsagePlante.alimentaire},
  nomsLocalises: {'fr': nomFr},
  besoins: BesoinsCulture(
    eau: BesoinEau.modere,
    soleil: NiveauSoleil.pleinSoleil,
    phMin: 6,
    phMax: 7,
  ),
  espacementCm: 40,
  dureeAvantRecolteJoursMin: 60,
  dureeAvantRecolteJoursMax: 80,
  periodes: const {},
  associationsBenefiques: bons,
  associationsNegatives: mauvais,
);

void main() {
  // Distinct initials so a node can be tapped by its letter (T/C/B/F), and
  // distinct families so each sits in its own bubble (ADR-0008 grouping).
  final fiches = [
    _fiche(
      'tomate',
      'Tomate',
      CategoriePlante.legume,
      bons: {'basilic'},
      mauvais: {'fenouil'},
      famille: 'Solanaceae',
    ),
    _fiche(
      'courgette',
      'Courgette',
      CategoriePlante.legume,
      famille: 'Cucurbitaceae',
    ),
    _fiche(
      'basilic',
      'Basilic',
      CategoriePlante.aromatique,
      bons: {'tomate'},
      famille: 'Lamiaceae',
    ),
    _fiche(
      'fenouil',
      'Fenouil',
      CategoriePlante.aromatique,
      mauvais: {'tomate'},
      famille: 'Apiaceae',
    ),
  ];

  Future<void> pomper(WidgetTester tester) async {
    final repoFiches = _MockFiches();
    final repoFamilles = _MockFamilles();
    final repoPotagers = _MockPotagers();
    when(() => repoFiches.obtenirToutes()).thenAnswer((_) async => fiches);
    when(() => repoFamilles.obtenirToutes()).thenAnswer((_) async => []);
    when(
      () => repoPotagers.obtenirPotagerActif(),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        // Overrides so the detail sheet (catalogueProvider / climate context)
        // can open on a node re-tap.
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => repoFiches),
          familleBotaniqueRepositoryProvider.overrideWith(
            (ref) async => repoFamilles,
          ),
          potagerRepositoryProvider.overrideWithValue(repoPotagers),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VueReseauCatalogue(
              fiches: fiches,
              varietesDe: (id) =>
                  fiches.where((f) => f.parentId == id).toList(),
              onAjouter: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a node per fiche and the idle hint', (tester) async {
    await pomper(tester);

    // One initial per fiche (T/C/B/F) and the "tap a plant" hint panel.
    for (final initiale in const ['T', 'C', 'B', 'F']) {
      expect(find.text(initiale), findsOneWidget, reason: initiale);
    }
    expect(
      find.text('Touchez une plante pour voir ses associations.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a node selects it and shows its panel', (tester) async {
    await pomper(tester);

    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    // The bottom panel shows the plant name (also surfaced as a node label since
    // #8a) and its association counts (panel-only).
    expect(find.text('Tomate'), findsWidgets);
    expect(find.textContaining('bon compagnon'), findsOneWidget);
    // The idle hint is gone.
    expect(
      find.text('Touchez une plante pour voir ses associations.'),
      findsNothing,
    );
  });

  testWidgets('searching by name selects and frames the matching species', (
    tester,
  ) async {
    await pomper(tester);

    // The search is collapsed to a magnifier; open it first (tweak #2).
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tom');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // The match is selected → its panel shows the name + counts.
    expect(find.text('Tomate'), findsWidgets);
    expect(find.textContaining('bon compagnon'), findsOneWidget);
  });

  testWidgets('name search ignores accents and case', (tester) async {
    await pomper(tester);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'TÔMA');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Tomate'), findsWidgets);
  });

  testWidgets('searching an unknown name shows a no-result hint', (
    tester,
  ) async {
    await pomper(tester);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Aucune plante trouvée'), findsOneWidget);
  });

  testWidgets('clearing the search drops the focus and collapses it', (
    tester,
  ) async {
    await pomper(tester);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tom');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    // Selected → the idle hint is gone.
    expect(
      find.text('Touchez une plante pour voir ses associations.'),
      findsNothing,
    );

    // Clearing (the close icon) deselects (back to the global view) and
    // collapses the field back to the magnifier (tweaks #2/#5).
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(
      find.text('Touchez une plante pour voir ses associations.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the display menu opens and exposes the two toggles', (
    tester,
  ) async {
    await pomper(tester);

    // Collapsed → the zoom controls are hidden behind a single tune button.
    expect(find.byTooltip('Zoomer'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Opened → zoom controls plus the links and family-names toggles.
    expect(find.byTooltip('Zoomer'), findsOneWidget);
    expect(find.byIcon(Icons.polyline_outlined), findsOneWidget);
    expect(find.byIcon(Icons.label_outline), findsOneWidget);

    // Toggling them does not throw.
    await tester.tap(find.byIcon(Icons.polyline_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.label_outline));
    await tester.pumpAndSettle();
  });

  testWidgets('selecting a plant groups its links by family (constellation)', (
    tester,
  ) async {
    await pomper(tester);

    await tester.tap(find.text('T')); // select Tomate (Solanaceae)
    await tester.pumpAndSettle();

    // Its links appear as family-grouped nodes: the family name above and the
    // species below. Basilic is Lamiaceae, Fenouil is Apiaceae.
    expect(find.text('Lamiaceae'), findsOneWidget);
    expect(find.text('Apiaceae'), findsOneWidget);
    expect(find.text('Basilic'), findsWidgets);
    expect(find.text('Fenouil'), findsWidgets);
  });

  testWidgets('the selected node merges into its own family group (#2)', (
    tester,
  ) async {
    // Tomate and Pomme de terre are both Solanaceae and companions: selecting
    // Tomate must fuse them under a single "Solanaceae" node listing both, with
    // no separate selected-node disc.
    final tomate = _fiche(
      'tomate',
      'Tomate',
      CategoriePlante.legume,
      bons: {'patate'},
      famille: 'Solanaceae',
    );
    final patate = _fiche(
      'patate',
      'Pomme de terre',
      CategoriePlante.legume,
      bons: {'tomate'},
      famille: 'Solanaceae',
    );
    final basilic = _fiche(
      'basilic',
      'Basilic',
      CategoriePlante.aromatique,
      bons: {'tomate'},
      famille: 'Lamiaceae',
    );

    await tester.pomperReseau(tomate, [patate, basilic]);
    await tester.tap(find.text('T')); // select Tomate (the hub initial)
    await tester.pumpAndSettle();

    // A single Solanaceae node lists both the selection and its same-family link.
    expect(find.text('Solanaceae'), findsOneWidget);
    expect(find.text('Tomate'), findsWidgets);
    expect(find.text('Pomme de terre'), findsWidgets);
    // A link of another family keeps its own group node.
    expect(find.text('Lamiaceae'), findsOneWidget);
    expect(find.text('Basilic'), findsWidgets);
  });

  // --- #3 : enlarged Voronoï hitbox (tap near a small node) ------------------

  testWidgets('a tap just off a small node still selects it (#3)', (
    tester,
  ) async {
    await pomper(tester);

    // Tap a little to the side of the dezoomed "T" disc — off the disc but
    // within the enlarged hitbox — and assert Tomate gets selected anyway.
    final centre = tester.getCenter(find.text('T'));
    await tester.tapAt(centre + const Offset(16, 0));
    await tester.pumpAndSettle();

    expect(find.text('Tomate'), findsWidgets);
    expect(find.textContaining('bon compagnon'), findsOneWidget);
    expect(
      find.text('Touchez une plante pour voir ses associations.'),
      findsNothing,
    );
  });

  testWidgets('re-tapping the selected node opens its detail sheet', (
    tester,
  ) async {
    await pomper(tester);

    // First tap selects Tomate.
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();
    // Since #2 the selection merges into its family group (no standalone disc);
    // its tappable name label is the first "Tomate" in tree order (canvas before
    // the panel). Re-tapping it opens the sheet.
    await tester.tap(find.text('Tomate').first);
    await tester.pumpAndSettle();

    // The detail sheet is open — its "add to garden" CTA is shown.
    expect(find.text('Ajouter au potager'), findsOneWidget);
  });

  testWidgets('the "à éviter" toggle is present and interactive', (
    tester,
  ) async {
    await pomper(tester);

    expect(find.text('Afficher les associations à éviter'), findsOneWidget);
    final toggle = find.byType(Switch);
    expect(toggle, findsOneWidget);

    // Toggling off then on must not throw and keeps the view alive.
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byType(VueReseauCatalogue), findsOneWidget);
  });

  // --- #7 : zoom + pan -------------------------------------------------------

  testWidgets('panning the canvas translates every node by the drag delta', (
    tester,
  ) async {
    await pomper(tester);

    final avant = tester.getCenter(find.text('T'));
    // Manual multi-step drag from an empty point on the left of the canvas
    // (past the side padding, far from the centred constellation, the top-right
    // controls and the bottom panel) so the scale recognizer engages. Since the
    // canvas also has an onTapUp (Voronoï hit-testing, #3), the scale gesture now
    // wins the arena only once the first move crosses the tap slop — that first
    // segment is absorbed, so we drag a few steps and expect the *remaining*
    // segments to pan every node.
    final rect = tester.getRect(find.byType(VueReseauCatalogue));
    final geste = await tester.startGesture(
      Offset(rect.left + 24, rect.center.dy),
    );
    await tester.pump();
    await geste.moveBy(const Offset(25, 0));
    await geste.moveBy(const Offset(25, 0));
    await geste.moveBy(const Offset(25, 0));
    await tester.pump();
    await geste.up();
    await tester.pumpAndSettle();

    final apres = tester.getCenter(find.text('T'));
    expect(
      apres.dx - avant.dx,
      greaterThan(30),
      reason: 'a horizontal pan should shift every node right',
    );
    expect(apres.dy - avant.dy, closeTo(0, 2));
  });

  testWidgets('zooming in moves a node, recenter restores the baseline', (
    tester,
  ) async {
    await pomper(tester);

    final baseline = tester.getCenter(find.text('T'));

    // The zoom/recenter controls live in the collapsible display menu; open it.
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Zoomer'));
    await tester.pumpAndSettle();
    final zoome = tester.getCenter(find.text('T'));
    expect(
      (zoome - baseline).distance,
      greaterThan(2),
      reason: 'zoom should reposition the node',
    );

    await tester.tap(find.byTooltip('Recentrer'));
    await tester.pumpAndSettle();
    final recentre = tester.getCenter(find.text('T'));
    expect(
      (recentre - baseline).distance,
      lessThan(1),
      reason: 'recenter should restore the baseline layout',
    );
  });

  // --- #8a : full names on selection + animated recadrage --------------------

  testWidgets('selecting a node names it and its links, not unrelated ones', (
    tester,
  ) async {
    await pomper(tester);

    // In the global view, names show where they fit (tweak #6); selecting a node
    // then restricts the labels to it and its links (Basilic/Fenouil are linked
    // to Tomate, Courgette is unrelated).
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    expect(find.text('Basilic'), findsOneWidget, reason: 'linked → named');
    expect(
      find.text('Fenouil'),
      findsOneWidget,
      reason: 'to-avoid link → named',
    );
    expect(
      find.text('Courgette'),
      findsNothing,
      reason: 'unrelated → not named',
    );
  });

  testWidgets('selecting a node animates a recadrage (fit-to-view)', (
    tester,
  ) async {
    await pomper(tester);

    final basilicAvant = tester.getCenter(find.text('B'));
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();
    final basilicApres = tester.getCenter(find.text('B'));

    // The fit-to-selection zoom repositions the framed (linked) nodes.
    expect(
      (basilicApres - basilicAvant).distance,
      greaterThan(2),
      reason: 'recadrage should reframe the selection and its links',
    );
  });

  // --- #8b : active anti-overlap --------------------------------------------

  testWidgets('selecting spreads the labels so none overlap', (tester) async {
    // A hub linked to several long-named spokes, in a constrained surface, so
    // the labels would collide without the anti-overlap separation.
    // Initials kept distinct and away from the hub's "T" so the hub node can be
    // tapped unambiguously by its initial.
    const noms = [
      'Capucine grimpante',
      'Souci officinal des jardins',
      'Bourrache bleue',
      'Rose trémière des murailles',
    ];
    final hub = _fiche(
      'hub',
      'Tomate cerise',
      CategoriePlante.legume,
      bons: {'s0', 's1', 's2', 's3'},
    );
    final spokes = [
      for (var i = 0; i < noms.length; i++)
        _fiche('s$i', noms[i], CategoriePlante.fleur, bons: {'hub'}),
    ];

    await tester.pomperReseau(hub, spokes);
    await tester.tap(find.text('T')); // the hub initial
    await tester.pumpAndSettle();

    _aucunChevauchement(tester, noms);
  });

  testWidgets('focus collapses same-family links into one grouped node', (
    tester,
  ) async {
    final hub = _fiche(
      'hub',
      'Tomate cerise',
      CategoriePlante.legume,
      bons: {'s0', 's1'},
      famille: 'Solanaceae',
    );
    // Both companions share the same family → one grouped node lists both.
    final spokes = [
      _fiche('s0', 'Capucine', CategoriePlante.fleur,
          bons: {'hub'}, famille: 'Tropaeolaceae'),
      _fiche('s1', 'Souci', CategoriePlante.fleur,
          bons: {'hub'}, famille: 'Tropaeolaceae'),
    ];

    await tester.pomperReseau(hub, spokes);
    await tester.tap(find.text('T')); // the hub initial
    await tester.pumpAndSettle();

    // The single family node shows the family once and lists both species.
    expect(find.text('Tropaeolaceae'), findsOneWidget);
    expect(find.text('Capucine'), findsWidgets);
    expect(find.text('Souci'), findsWidgets);
  });

  testWidgets('the fit keeps every label within the canvas (no clipping)', (
    tester,
  ) async {
    const noms = [
      'Capucine grimpante',
      'Souci officinal des jardins',
      'Bourrache bleue',
      'Rose trémière des murailles',
    ];
    final hub = _fiche(
      'hub',
      'Tomate cerise',
      CategoriePlante.legume,
      bons: {'s0', 's1', 's2', 's3'},
    );
    final spokes = [
      for (var i = 0; i < noms.length; i++)
        _fiche('s$i', noms[i], CategoriePlante.fleur, bons: {'hub'}),
    ];

    await tester.pomperReseau(hub, spokes);
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    final canvas = tester.getRect(find.byType(VueReseauCatalogue));
    for (final n in noms) {
      final r = tester.getRect(find.text(n));
      expect(
        r.left,
        greaterThanOrEqualTo(canvas.left - 0.5),
        reason: '"$n" is clipped on the left',
      );
      expect(
        r.right,
        lessThanOrEqualTo(canvas.right + 0.5),
        reason: '"$n" is clipped on the right',
      );
    }
  });

  testWidgets('a wide selection shrinks to fit without overlap or clipping', (
    tester,
  ) async {
    // Many long-named companions: at the initial scale the spread footprints
    // overflow, so the fit must shrink (re-spreading) until they fit.
    const noms = [
      'Aneth odorant',
      'Bourrache officinale',
      'Capucine grimpante',
      'Souci des jardins',
      'Lavande vraie',
      'Sauge officinale',
      'Mélisse citronnelle',
      'Camomille romaine',
    ];
    final hub = _fiche(
      'hub',
      'Radis rose',
      CategoriePlante.legume,
      bons: {for (var i = 0; i < noms.length; i++) 's$i'},
    );
    final spokes = [
      for (var i = 0; i < noms.length; i++)
        _fiche('s$i', noms[i], CategoriePlante.fleur, bons: {'hub'}),
    ];

    await tester.pomperReseau(hub, spokes);
    await tester.tap(find.text('R')); // the hub initial
    await tester.pumpAndSettle();

    _aucunChevauchement(tester, noms);
    final canvas = tester.getRect(find.byType(VueReseauCatalogue));
    for (final n in noms) {
      final r = tester.getRect(find.text(n));
      expect(
        r.left,
        greaterThanOrEqualTo(canvas.left - 0.5),
        reason: '"$n" left',
      );
      expect(
        r.right,
        lessThanOrEqualTo(canvas.right + 0.5),
        reason: '"$n" right',
      );
    }
  });

  testWidgets('a zoom-out re-spreads the labels after the idle delay', (
    tester,
  ) async {
    const noms = [
      'Capucine grimpante',
      'Souci officinal des jardins',
      'Bourrache bleue',
      'Rose trémière des murailles',
    ];
    final hub = _fiche(
      'hub',
      'Tomate cerise',
      CategoriePlante.legume,
      bons: {'s0', 's1', 's2', 's3'},
    );
    final spokes = [
      for (var i = 0; i < noms.length; i++)
        _fiche('s$i', noms[i], CategoriePlante.fleur, bons: {'hub'}),
    ];

    await tester.pomperReseau(hub, spokes);
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    // Open the collapsible display menu to reach the zoom controls.
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Zooming out shrinks the on-screen gaps until the constant-size labels
    // collide again.
    for (var k = 0; k < 3; k++) {
      await tester.tap(find.byTooltip('Dézoomer'));
      await tester.pump();
    }

    // After the idle delay (>1s), a single recompute re-spreads them.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    _aucunChevauchement(tester, noms);
  });

  // --- #9 : varieties of the selected species --------------------------------

  testWidgets('selecting a species lists its varieties; tapping one opens it', (
    tester,
  ) async {
    final tomate = _fiche(
      'tomate',
      'Tomate',
      CategoriePlante.legume,
      bons: {'basilic'},
    );
    final basilic = _fiche(
      'basilic',
      'Basilic',
      CategoriePlante.aromatique,
      bons: {'tomate'},
    );
    final coeur = _fiche('v1', 'Coeur de boeuf', CategoriePlante.legume);
    final roma = _fiche('v2', 'Roma', CategoriePlante.legume);

    await tester.pomperEspece(
      [tomate, basilic],
      {
        'tomate': [coeur, roma],
      },
    );

    // No selection yet → no variety rows.
    expect(find.text('Coeur de boeuf'), findsNothing);

    await tester.tap(find.text('T')); // select the Tomate species
    await tester.pumpAndSettle();

    // Expand BOX 2 (the fiches sheet) so every variety is laid out.
    await tester.drag(
      find.text('Afficher les associations à éviter'),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coeur de boeuf'), findsOneWidget);
    expect(find.text('Roma'), findsOneWidget);

    // Tapping a variety opens its detail sheet.
    await tester.tap(find.text('Coeur de boeuf'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter au potager'), findsOneWidget);
  });

  // --- #10 : dragging BOX 2 up shrinks BOX 1 (capped at half the screen) ------

  testWidgets('expanding BOX 2 is capped at half the screen', (tester) async {
    final tomate = _fiche(
      'tomate',
      'Tomate',
      CategoriePlante.legume,
      bons: {'basilic'},
    );
    final basilic = _fiche(
      'basilic',
      'Basilic',
      CategoriePlante.aromatique,
      bons: {'tomate'},
    );
    final varietes = [
      for (var i = 0; i < 6; i++)
        _fiche('v$i', 'Variété numéro $i', CategoriePlante.legume),
    ];

    await tester.pomperEspece([tomate, basilic], {'tomate': varietes});
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    // The companion's full-name label is shown — and stays shown whether BOX 1
    // is reduced or not (one uniform behaviour).
    expect(find.text('Basilic'), findsOneWidget);

    // Drag BOX 2 up hard → it grows but is capped at half the screen, so its
    // content stays in the lower half (its top below the middle).
    await tester.drag(find.text('Voir la fiche'), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Basilic'), findsOneWidget, reason: 'names stay visible');

    final vue = tester.getRect(find.byType(VueReseauCatalogue));
    final hautFeuille = tester
        .getRect(find.text('Afficher les associations à éviter'))
        .top;
    expect(hautFeuille, greaterThanOrEqualTo(vue.top + vue.height * 0.45));
  });

  testWidgets('the reduced network keeps updating live (zoom)', (tester) async {
    final tomate = _fiche(
      'tomate',
      'Tomate',
      CategoriePlante.legume,
      bons: {'basilic'},
    );
    final basilic = _fiche(
      'basilic',
      'Basilic',
      CategoriePlante.aromatique,
      bons: {'tomate'},
    );

    await tester.pomperEspece([tomate, basilic], const {});
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    // Reduce BOX 1 (expand BOX 2).
    await tester.drag(find.text('Voir la fiche'), const Offset(0, -400));
    await tester.pumpAndSettle();

    // Zooming in must move a node *now* (live), not only once BOX 2 is lowered.
    // Track the linked companion's label inside the focus group (a canvas node
    // that moves with the zoom); since #2 the selection itself merges into its
    // family group's disc, so "T" is no longer a standalone constellation node.
    final avant = tester.getCenter(find.text('Basilic'));
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zoomer'));
    await tester.pumpAndSettle();
    final apres = tester.getCenter(find.text('Basilic'));
    expect(
      (apres - avant).distance,
      greaterThan(2),
      reason: 'the reduced network must repaint live',
    );
  });

  testWidgets('resizing BOX 1 re-fits the selection to the new box size', (
    tester,
  ) async {
    final tomate = _fiche(
      'tomate',
      'Tomate',
      CategoriePlante.legume,
      bons: {'basilic'},
    );
    final basilic = _fiche(
      'basilic',
      'Basilic',
      CategoriePlante.aromatique,
      bons: {'tomate'},
    );

    await tester.pomperEspece([tomate, basilic], const {});
    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();
    final avant = tester.getCenter(find.text('T').first);

    // Shrink BOX 1 a bit (grow BOX 2, staying below the compact threshold so the
    // node stays present) → the framing must follow the new box.
    await tester.drag(
      find.text('Afficher les associations à éviter'),
      const Offset(0, -70),
    );
    await tester.pumpAndSettle();
    // Let the debounced re-fit fire (it is timer-based, not frame-based).
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    final apres = tester.getCenter(find.text('T').first);
    expect(
      (apres - avant).distance,
      greaterThan(5),
      reason: 'the selection should be re-fitted to the resized box',
    );
  });

  testWidgets('a heavily-connected selection still shows every name', (
    tester,
  ) async {
    // One uniform behaviour: full names are always shown, even with many
    // companions (off-screen is accepted; no special-casing/cap).
    final hub = _fiche(
      'laitue',
      'Laitue',
      CategoriePlante.legume,
      bons: {for (var i = 0; i < 15; i++) 's$i'},
    );
    final spokes = [
      for (var i = 0; i < 15; i++)
        _fiche(
          's$i',
          'Compagnon numéro $i',
          CategoriePlante.aromatique,
          bons: {'laitue'},
        ),
    ];

    await tester.pomperReseau(hub, spokes);
    await tester.tap(find.text('L').first); // select Laitue
    await tester.pumpAndSettle();

    // Companion labels are rendered (uniform behaviour), not dropped.
    expect(find.text('Compagnon numéro 0'), findsOneWidget);
    expect(find.text('Compagnon numéro 14'), findsOneWidget);
  });
}

/// Asserts no two of the named labels overlap on screen (#8b).
void _aucunChevauchement(WidgetTester tester, List<String> noms) {
  final rects = [for (final n in noms) tester.getRect(find.text(n))];
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      expect(
        rects[i].overlaps(rects[j]),
        isFalse,
        reason: 'labels "${noms[i]}" and "${noms[j]}" must not overlap',
      );
    }
  }
}

extension on WidgetTester {
  /// Mounts the network view with a [hub] + [spokes] in a phone-sized surface
  /// where the clustered nodes' labels start out overlapping, for the #8b
  /// anti-overlap tests.
  Future<void> pomperReseau(FichePlante hub, List<FichePlante> spokes) async {
    final fiches = [hub, ...spokes];
    final repoFiches = _MockFiches();
    final repoFamilles = _MockFamilles();
    final repoPotagers = _MockPotagers();
    when(() => repoFiches.obtenirToutes()).thenAnswer((_) async => fiches);
    when(() => repoFamilles.obtenirToutes()).thenAnswer((_) async => []);
    when(
      () => repoPotagers.obtenirPotagerActif(),
    ).thenAnswer((_) async => null);

    await pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => repoFiches),
          familleBotaniqueRepositoryProvider.overrideWith(
            (ref) async => repoFamilles,
          ),
          potagerRepositoryProvider.overrideWithValue(repoPotagers),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 390,
                height: 740,
                child: VueReseauCatalogue(
                  fiches: fiches,
                  varietesDe: (id) =>
                      fiches.where((f) => f.parentId == id).toList(),
                  onAjouter: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await pumpAndSettle();
  }

  /// Mounts the network view over [noeuds] with [varietes] looked up by species
  /// id, for the #9/#10 tests. [toutes] feeds the detail sheet's catalogue.
  Future<void> pomperEspece(
    List<FichePlante> noeuds,
    Map<String, List<FichePlante>> varietes,
  ) async {
    final repoFiches = _MockFiches();
    final repoFamilles = _MockFamilles();
    final repoPotagers = _MockPotagers();
    final toutes = [noeuds, ...varietes.values].expand((e) => e).toList();
    when(() => repoFiches.obtenirToutes()).thenAnswer((_) async => toutes);
    when(() => repoFamilles.obtenirToutes()).thenAnswer((_) async => []);
    when(
      () => repoPotagers.obtenirPotagerActif(),
    ).thenAnswer((_) async => null);

    await pumpWidget(
      ProviderScope(
        overrides: [
          fichePlanteRepositoryProvider.overrideWith((ref) async => repoFiches),
          familleBotaniqueRepositoryProvider.overrideWith(
            (ref) async => repoFamilles,
          ),
          potagerRepositoryProvider.overrideWithValue(repoPotagers),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VueReseauCatalogue(
              fiches: noeuds,
              varietesDe: (id) => varietes[id] ?? const [],
              onAjouter: (_) {},
            ),
          ),
        ),
      ),
    );
    await pumpAndSettle();
  }
}
