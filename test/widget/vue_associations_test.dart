// Widget tests for the Associations view (ADR-0010): each companion shows its
// typed mechanism label and, when present, the editorial reason — and a bare
// pair shows neither (nothing invented).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_besoin.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_benefice_association.dart';
import 'package:pot_a_gerer/domain/enums/type_conflit_association.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/association_benefique.dart';
import 'package:pot_a_gerer/domain/value_objects/association_conflit.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/poids_association.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';
import 'package:pot_a_gerer/domain/value_objects/profil_ponderation_associations.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/fiche_plante_detail.dart';
import 'package:pot_a_gerer/presentation/widgets/vue_associations.dart';

FichePlante _fiche(
  String id, {
  String famille = 'Test',
  Set<UsagePlante> usages = const {UsagePlante.alimentaire},
  List<AssociationBenefique> benefiques = const [],
  List<AssociationConflit> negatives = const [],
  bool fixeAzote = false,
  NiveauBesoin? besoinAzote,
  bool cultureVerticale = false,
  int? hauteurMax,
}) =>
    FichePlante(
      id: id,
      nomScientifique: '$id sp',
      familleBotanique: famille,
      categorie: CategoriePlante.legume,
      usages: usages,
      nomsLocalises: {'fr': id},
      besoins: BesoinsCulture(
        eau: BesoinEau.modere,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: 40,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 80,
      cultureVerticale: cultureVerticale,
      hauteurAdulteCmMax: hauteurMax,
      fixeAzote: fixeAzote,
      besoinAzote: besoinAzote,
      associationsBenefiques: benefiques,
      associationsNegatives: negatives,
    );

void main() {
  Future<void> ouvrir(
    WidgetTester tester,
    FichePlante centre,
    List<FichePlante> catalogue, {
    AccesNiveau? acces,
    ProfilPonderationAssociations? profil,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => afficherVueAssociations(context, centre,
                      catalogue, acces: acces, profil: profil),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the typed mechanism; the reason is not in the view '
      '(moved to the sheet, ADR-0012)', (tester) async {
    final centre = _fiche('centre', benefiques: [
      AssociationBenefique(
        cibleId: 'compagnon',
        mecanisme: TypeBeneficeAssociation.attractionPollinisateurs,
        raisonI18n: const {'fr': 'Attire les abeilles'},
      ),
    ], negatives: [
      AssociationConflit(
        cibleId: 'ennemi',
        mecanisme: TypeConflitAssociation.memeFamilleRavageurs,
      ),
    ]);
    final compagnon = _fiche('compagnon');
    final ennemi = _fiche('ennemi');

    await ouvrir(tester, centre, [centre, compagnon, ennemi]);

    // Mechanism chips are shown in the constellation…
    expect(find.text('Attire les pollinisateurs'), findsOneWidget);
    expect(find.text('Même famille'), findsOneWidget);
    // …but the long editorial reason is NOT (it goes to the sheet banner).
    expect(find.text('Attire les abeilles'), findsNothing);
  });

  testWidgets('the opened sheet shows the full reason in a banner (ADR-0012)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => afficherFichePlanteDetail(
                    context,
                    _fiche('tomate'),
                    contexte: const ContexteAssociation(
                      bon: true,
                      mecanisme: "Fixe l'azote",
                      raison: 'Enrichit le sol pour la tomate',
                    ),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // Banner: mechanism title + full (untruncated) editorial reason.
    expect(find.text("Fixe l'azote"), findsOneWidget);
    expect(find.text('Enrichit le sol pour la tomate'), findsOneWidget);
  });

  testWidgets(
      'the banner lists every factor of a derived suggestion (ADR-0014)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => afficherFichePlanteDetail(
                    context,
                    _fiche('tomate'),
                    contexte: const ContexteAssociation(
                      bon: true,
                      mecanisme: "Fixe l'azote",
                      suggere: true,
                      confiance: 'élevée',
                      facteurs: [
                        'Haricot fixe l\'azote de l\'air dans le sol',
                        'Tomate est gourmande en azote (besoin élevé)',
                      ],
                    ),
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Suggestion · élevée'), findsOneWidget);
    expect(find.text('Pourquoi cette suggestion :'), findsOneWidget);
    expect(find.textContaining('fixe l\'azote de l\'air'), findsOneWidget);
    expect(find.textContaining('gourmande en azote'), findsOneWidget);
  });

  testWidgets(
      'an untyped curated pair shows the name under a neutral "Autre" marker '
      '(ADR-0013)', (tester) async {
    final centre = _fiche('centre', benefiques: [
      AssociationBenefique(cibleId: 'compagnon'),
    ]);
    final compagnon = _fiche('compagnon');

    await ouvrir(tester, centre, [centre, compagnon]);

    // The companion is listed; the typed mechanism is absent, but the pair is no
    // longer orphaned — it carries the generic "Autre" chip (full detail lives in
    // the sheet banner).
    expect(find.text('compagnon'), findsOneWidget);
    expect(find.text('Attire les pollinisateurs'), findsNothing);
    expect(find.text('Autre'), findsOneWidget);
    // A curated cluster shows the "Hors moteur" line (ADR-0013 §7); the
    // suggestion dropdown shows the current selection ("Tout" by default), so
    // "Hors moteur" appears exactly once (the cluster label only).
    expect(find.text('Hors moteur'), findsOneWidget);
  });

  testWidgets(
      'tapping a cluster bubble opens its sheet (regression guard, ADR-0013 §3)',
      (tester) async {
    final centre = _fiche('centre', benefiques: [
      AssociationBenefique(
        cibleId: 'compagnon',
        mecanisme: TypeBeneficeAssociation.attractionPollinisateurs,
        raisonI18n: const {'fr': 'Attire les abeilles'},
      ),
    ]);
    final compagnon = _fiche('compagnon');

    await ouvrir(tester, centre, [centre, compagnon]);

    // Tapping the member bubble/name opens the sheet, whose banner carries the
    // full editorial reason (proves the node is hit-testable again).
    await tester.tap(find.text('compagnon'));
    await tester.pumpAndSettle();
    expect(find.text('Attire les abeilles'), findsOneWidget);
  });

  group('derived suggestions gated by experience level (ADR-0010/0009)', () {
    // haricot (nitrogen fixer) + mais (heavy feeder) → derived fixationAzote.
    final haricot = _fiche('haricot', famille: 'Fabaceae', fixeAzote: true);
    final mais =
        _fiche('mais', famille: 'Poaceae', besoinAzote: NiveauBesoin.eleve);

    testWidgets('beginner sees no derived suggestion', (tester) async {
      await ouvrir(tester, haricot, [haricot, mais],
          acces: const AccesNiveau(NiveauExperience.debutant));
      expect(find.text("Fixe l'azote"), findsNothing);
      expect(find.text('Suggestion · élevée'), findsNothing);
    });

    testWidgets('intermédiaire sees the derived suggestion with confidence',
        (tester) async {
      await ouvrir(tester, haricot, [haricot, mais],
          acces: const AccesNiveau(NiveauExperience.intermediaire));
      expect(find.text('mais'), findsOneWidget);
      expect(find.text("Fixe l'azote"), findsOneWidget);
      expect(find.text('Suggestion · élevée'), findsOneWidget);
    });

    testWidgets('tapping the suggestion lists its real factors end-to-end '
        '(ADR-0014)', (tester) async {
      await ouvrir(tester, haricot, [haricot, mais],
          acces: const AccesNiveau(NiveauExperience.intermediaire));
      await tester.tap(find.text('mais'));
      await tester.pumpAndSettle();
      // The engine's criteria flow into concrete factor sentences with names.
      expect(find.text('Pourquoi cette suggestion :'), findsOneWidget);
      expect(find.textContaining('fixe l\'azote de l\'air'), findsOneWidget);
      expect(find.textContaining('gourmande en azote'), findsOneWidget);
    });
  });

  group('filtre par direction (ADR-0012)', () {
    // centre déclare → donne (vers planteDonne) ; planteRecoit déclare centre → reçoit.
    final centre = _fiche('centre', benefiques: [
      AssociationBenefique(cibleId: 'planteDonne'),
    ]);
    final planteDonne = _fiche('planteDonne');
    final planteRecoit = _fiche('planteRecoit',
        benefiques: [AssociationBenefique(cibleId: 'centre')]);
    final catalogue = [centre, planteDonne, planteRecoit];

    testWidgets('« Tout » montre les deux directions', (tester) async {
      await ouvrir(tester, centre, catalogue);
      expect(find.text('planteDonne'), findsOneWidget);
      expect(find.text('planteRecoit'), findsOneWidget);
    });

    testWidgets('« Reçoit » ne garde que les associations reçues',
        (tester) async {
      await ouvrir(tester, centre, catalogue);
      // Open the Association dropdown (first PopupMenuButton = direction).
      await tester.tap(find.byType(PopupMenuButton<Object?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reçoit'));
      await tester.pumpAndSettle();
      expect(find.text('planteRecoit'), findsOneWidget);
      expect(find.text('planteDonne'), findsNothing);
    });

    testWidgets('« Donne » ne garde que les associations données',
        (tester) async {
      await ouvrir(tester, centre, catalogue);
      await tester.tap(find.byType(PopupMenuButton<Object?>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Donne'));
      await tester.pumpAndSettle();
      expect(find.text('planteDonne'), findsOneWidget);
      expect(find.text('planteRecoit'), findsNothing);
    });
  });

  group('scoring & declutter (ADR-0011)', () {
    const intermediaire = AccesNiveau(NiveauExperience.intermediaire);

    // mais (living stake, tall) + haricot (climber) → tuteurStructurel (gainDePlace).
    // Distinct families so no same-family conflict competes with the benefit.
    final mais = _fiche('mais',
        famille: 'Poaceae',
        usages: {UsagePlante.alimentaire, UsagePlante.tuteurVivant},
        hauteurMax: 200);
    final haricot = _fiche('haricot', famille: 'Fabaceae', cultureVerticale: true);

    testWidgets('default profile keeps a gainDePlace suggestion',
        (tester) async {
      await ouvrir(tester, mais, [mais, haricot], acces: intermediaire);
      expect(find.text('Tuteur naturel'), findsOneWidget);
    });

    testWidgets('an ignored family drops its derived suggestions',
        (tester) async {
      await ouvrir(tester, mais, [mais, haricot],
          acces: intermediaire,
          profil: ProfilPonderationAssociations.defaut().avec(
              FamilleEffetAssociation.gainDePlace, PoidsAssociation.ignore));
      expect(find.text('Tuteur naturel'), findsNothing);
    });

    testWidgets(
        'same-mechanism suggestions form a single cluster, not a capped list '
        '(ADR-0013)', (tester) async {
      // One fixer centre + 7 heavy feeders → 7 derived "Fixe l'azote" benefits,
      // all in the same direction → ONE cluster (one shared label), so the
      // per-side cap no longer hides anything: no "voir plus".
      final haricot = _fiche('haricot', famille: 'Fabaceae', fixeAzote: true);
      final gourmandes = [
        for (var i = 0; i < 7; i++)
          _fiche('g$i', famille: 'Poaceae', besoinAzote: NiveauBesoin.eleve),
      ];

      await ouvrir(tester, haricot, [haricot, ...gourmandes],
          acces: intermediaire);

      // One shared mechanism label for the whole cluster…
      expect(find.text("Fixe l'azote"), findsOneWidget);
      // …every member is still shown individually…
      for (var i = 0; i < 7; i++) {
        expect(find.text('g$i'), findsOneWidget);
      }
      // …and nothing is hidden behind the toggle.
      expect(find.textContaining('Voir'), findsNothing);
    });
  });

  group('conflict precedence — one side per pair (ADR-0013 §2/§3)', () {
    const intermediaire = AccesNiveau(NiveauExperience.intermediaire);

    testWidgets('a pair that is both beneficial and conflicting shows only on '
        'the to-avoid side', (tester) async {
      // centre × voisin: living-stake support (benefit) AND same family
      // (conflict) → the warning wins, the bubble appears once, to-avoid.
      final centre = _fiche('centre',
          famille: 'Solanaceae',
          usages: {UsagePlante.alimentaire, UsagePlante.tuteurVivant},
          hauteurMax: 200);
      final voisin =
          _fiche('voisin', famille: 'Solanaceae', cultureVerticale: true);

      await ouvrir(tester, centre, [centre, voisin], acces: intermediaire);

      // Listed exactly once, under the conflict label (same family), never the
      // support benefit.
      expect(find.text('voisin'), findsOneWidget);
      expect(find.text('Même famille'), findsOneWidget);
      expect(find.text('Tuteur naturel'), findsNothing);
    });
  });

  group('preferences banner (ADR-0013 §4)', () {
    testWidgets('default profile → "normales (par défaut)"', (tester) async {
      final centre = _fiche('centre',
          benefiques: [AssociationBenefique(cibleId: 'compagnon')]);
      await ouvrir(tester, centre, [centre, _fiche('compagnon')]);
      expect(
          find.textContaining('normales (par défaut)'), findsOneWidget);
    });

    testWidgets('a tuned profile names the adjusted family only (no prefix)',
        (tester) async {
      final centre = _fiche('centre',
          benefiques: [AssociationBenefique(cibleId: 'compagnon')]);
      await ouvrir(tester, centre, [centre, _fiche('compagnon')],
          profil: ProfilPonderationAssociations.defaut().avec(
              FamilleEffetAssociation.fertilite, PoidsAssociation.fort));
      // The tuned family is shown; the verbose prefix is gone (ADR-0013 §7).
      expect(find.textContaining('Fertilité du sol'), findsOneWidget);
      expect(find.textContaining('Préférences personnalisées'), findsNothing);
    });
  });
}
