// Widget tests for the Associations view (ADR-0010): each companion shows its
// typed mechanism label and, when present, the editorial reason — and a bare
// pair shows neither (nothing invented).
import 'package:flutter/material.dart';
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
      MaterialApp(
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
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the typed mechanism and the editorial reason', (
    tester,
  ) async {
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

    // Benefit: mechanism label + reason are both shown.
    expect(find.text('Attire les pollinisateurs'), findsOneWidget);
    expect(find.text('Attire les abeilles'), findsOneWidget);
    // Conflict: mechanism label shown (no reason declared).
    expect(find.text('Même famille (ravageurs partagés)'), findsOneWidget);
  });

  testWidgets('a bare pair shows the name only — no mechanism, no reason', (
    tester,
  ) async {
    final centre = _fiche('centre', benefiques: [
      AssociationBenefique(cibleId: 'compagnon'),
    ]);
    final compagnon = _fiche('compagnon');

    await ouvrir(tester, centre, [centre, compagnon]);

    // The companion is listed (its name appears) but no mechanism chip text.
    expect(find.text('compagnon'), findsOneWidget);
    expect(find.text('Attire les pollinisateurs'), findsNothing);
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
      expect(find.text('Suggéré · confiance élevée'), findsNothing);
    });

    testWidgets('intermédiaire sees the derived suggestion with confidence',
        (tester) async {
      await ouvrir(tester, haricot, [haricot, mais],
          acces: const AccesNiveau(NiveauExperience.intermediaire));
      expect(find.text('mais'), findsOneWidget);
      expect(find.text("Fixe l'azote"), findsOneWidget);
      expect(find.text('Suggéré · confiance élevée'), findsOneWidget);
    });
  });

  group('scoring & declutter (ADR-0011)', () {
    const intermediaire = AccesNiveau(NiveauExperience.intermediaire);

    // mais (living stake, tall) + haricot (climber) → tuteurStructurel (gainDePlace).
    final mais = _fiche('mais',
        usages: {UsagePlante.alimentaire, UsagePlante.tuteurVivant},
        hauteurMax: 200);
    final haricot = _fiche('haricot', cultureVerticale: true);

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

    testWidgets('caps derived suggestions per side behind "voir plus"',
        (tester) async {
      // One fixer centre + 7 heavy feeders → 7 derived benefits, capped at 5.
      final haricot = _fiche('haricot', famille: 'Fabaceae', fixeAzote: true);
      final gourmandes = [
        for (var i = 0; i < 7; i++)
          _fiche('g$i', famille: 'Poaceae', besoinAzote: NiveauBesoin.eleve),
      ];

      await ouvrir(tester, haricot, [haricot, ...gourmandes],
          acces: intermediaire);

      // 7 - 5 = 2 hidden → the toggle offers to reveal them.
      expect(find.text('Voir 2 suggestions de plus'), findsOneWidget);

      await tester.tap(find.text('Voir 2 suggestions de plus'));
      await tester.pumpAndSettle();
      expect(find.text('Voir moins'), findsOneWidget);
    });
  });
}
