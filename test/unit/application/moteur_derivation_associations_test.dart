import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/moteur_derivation_associations.dart';
import 'package:pot_a_gerer/application/engine/suggestion_association.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/enums/critere_association.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/enracinement_plante.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/charge_tuteur.dart';
import 'package:pot_a_gerer/domain/enums/niveau_besoin.dart';
import 'package:pot_a_gerer/domain/enums/niveau_confiance.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/sens_association.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/type_benefice_association.dart';
import 'package:pot_a_gerer/domain/enums/type_conflit_association.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/association_benefique.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';

FichePlante _f(
  String id, {
  String famille = 'Test',
  CategoriePlante categorie = CategoriePlante.legume,
  SousTypeLegume? sousType,
  Set<UsagePlante> usages = const {UsagePlante.alimentaire},
  NiveauSoleil soleil = NiveauSoleil.pleinSoleil,
  NiveauSoleil? soleilMin,
  BesoinEau eau = BesoinEau.modere,
  int espacementCm = 40,
  int dureeMin = 60,
  int dureeMax = 80,
  bool cultureVerticale = false,
  ChargeTuteur? chargeTuteur,
  bool fixeAzote = false,
  NiveauBesoin? besoinAzote,
  int? hauteurMax,
  EnracinementPlante? enracinement,
  Set<String> repulsifContre = const {},
  Set<String> piegeA = const {},
  List<AssociationBenefique>? benefiques,
}) =>
    FichePlante(
      id: id,
      nomScientifique: '$id sp',
      familleBotanique: famille,
      categorie: categorie,
      sousType: sousType,
      usages: usages,
      nomsLocalises: {'fr': id},
      besoins: BesoinsCulture(
        eau: eau,
        soleil: soleil,
        soleilMin: soleilMin,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: espacementCm,
      dureeAvantRecolteJoursMin: dureeMin,
      dureeAvantRecolteJoursMax: dureeMax,
      cultureVerticale: cultureVerticale,
      chargeTuteur: chargeTuteur,
      fixeAzote: fixeAzote,
      besoinAzote: besoinAzote,
      hauteurAdulteCmMax: hauteurMax,
      enracinement: enracinement,
      repulsifContre: repulsifContre,
      piegeA: piegeA,
      associationsBenefiques: benefiques,
    );

/// Resolver over a few families keyed by normalised name.
ResolveurFamille _familles(List<FamilleBotanique> familles) {
  final parCle = {for (final f in familles) f.id: f};
  return (brute) => parCle[FamilleBotanique.normaliserCle(brute)];
}

FamilleBotanique _famille(String id,
        {Set<String> ravageurs = const {}, Set<String> maladies = const {}}) =>
    FamilleBotanique(
      id: id,
      nomScientifique: id,
      categories: const {CategoriePlante.legume},
      nomsLocalises: {'fr': id},
      ravageursCommuns: ravageurs,
      maladiesCommunes: maladies,
    );

/// The benefit mechanisms found in [suggestions].
Set<TypeBeneficeAssociation> _benefices(List<SuggestionAssociation> s) => {
      for (final x in s)
        if (x is SuggestionBenefique) x.mecanisme,
    };

Set<TypeConflitAssociation> _conflits(List<SuggestionAssociation> s) => {
      for (final x in s)
        if (x is SuggestionConflit) x.mecanisme,
    };

void main() {
  const moteur = MoteurDerivationAssociations();

  group('deriver — règles bénéfiques', () {
    test('fixationAzote: légumineuse × gourmande en azote (eleve)', () {
      final a = _f('haricot', fixeAzote: true);
      final b = _f('mais', besoinAzote: NiveauBesoin.eleve);
      final s = moteur.deriver(a, b);
      final fix = s.whereType<SuggestionBenefique>().firstWhere(
          (x) => x.mecanisme == TypeBeneficeAssociation.fixationAzote);
      expect(fix.confiance, NiveauConfiance.eleve);
      expect(fix.cibleId, 'mais');
      // ADR-0014: the suggestion carries the explicit criteria behind it.
      expect(fix.criteres, {
        CritereAssociation.sourceFixeAzote,
        CritereAssociation.cibleGourmandeAzote,
      });
    });

    test('attractionPollinisateurs: mellifère × entomophile (fruit)', () {
      final a = _f('bourrache', usages: {UsagePlante.mellifere});
      final b = _f('courgette', sousType: SousTypeLegume.legumeFruit);
      expect(_benefices(moteur.deriver(a, b)),
          contains(TypeBeneficeAssociation.attractionPollinisateurs));
    });

    test('tuteurStructurel: support × grimpante non lourde', () {
      final mais = _f('mais', usages: {UsagePlante.tuteurVivant});
      final haricot = _f('haricot', cultureVerticale: true);
      expect(_benefices(moteur.deriver(mais, haricot)),
          contains(TypeBeneficeAssociation.tuteurStructurel));
    });

    test('tuteurStructurel: refusé pour une grimpante lourde', () {
      final mais = _f('mais', usages: {UsagePlante.tuteurVivant});
      final courge = _f('courge',
          cultureVerticale: true, chargeTuteur: ChargeTuteur.lourde);
      expect(_benefices(moteur.deriver(mais, courge)),
          isNot(contains(TypeBeneficeAssociation.tuteurStructurel)));
    });

    test('etagementLumiere: haute plein soleil × basse qui tolère (faible)', () {
      final mais = _f('mais', hauteurMax: 200);
      final laitue =
          _f('laitue', soleilMin: NiveauSoleil.miOmbre, hauteurMax: 30);
      final s = moteur.deriver(mais, laitue).whereType<SuggestionBenefique>();
      final eta = s.firstWhere(
          (x) => x.mecanisme == TypeBeneficeAssociation.etagementLumiere);
      // Tolère seulement → confiance faible + critère "tolère" explicite (ADR-0014).
      expect(eta.confiance, NiveauConfiance.faible);
      expect(eta.criteres, contains(CritereAssociation.cibleTolereOmbre));
      expect(eta.criteres, contains(CritereAssociation.cibleNettementPlusBasse));
    });

    test('etagementLumiere: ne se déclenche PAS si la cible n est pas plus basse '
        '(ADR-0014)', () {
      final mais = _f('mais', hauteurMax: 200);
      // Tournesol tolère l ombre mais reste grand → pas d étagement.
      final tournesol = _f('tournesol',
          soleilMin: NiveauSoleil.miOmbre, hauteurMax: 220);
      expect(_benefices(moteur.deriver(mais, tournesol)),
          isNot(contains(TypeBeneficeAssociation.etagementLumiere)));
    });

    test('etagementLumiere: cible qui PRÉFÈRE l ombre → confiance moyenne', () {
      final mais = _f('mais', hauteurMax: 200);
      final epinard = _f('epinard', soleil: NiveauSoleil.miOmbre, hauteurMax: 30);
      final eta = moteur
          .deriver(mais, epinard)
          .whereType<SuggestionBenefique>()
          .firstWhere(
              (x) => x.mecanisme == TypeBeneficeAssociation.etagementLumiere);
      expect(eta.confiance, NiveauConfiance.moyen);
      expect(eta.criteres, contains(CritereAssociation.ciblePrefereOmbre));
    });

    test('successionTemporelle: cycle court × cycle long', () {
      final radis = _f('radis', dureeMin: 25, dureeMax: 40);
      final carotte = _f('carotte', dureeMin: 110, dureeMax: 140);
      expect(_benefices(moteur.deriver(radis, carotte)),
          contains(TypeBeneficeAssociation.successionTemporelle));
    });

    test('repulsionRavageur: répulsif ciblant un ravageur de la famille de B', () {
      final oeillet =
          _f('oeillet', usages: {UsagePlante.repulsif}, repulsifContre: {'nematode'});
      final tomate = _f('tomate', famille: 'Solanaceae');
      final familles = _familles([_famille('solanaceae', ravageurs: {'nematode'})]);
      final s = moteur.deriver(oeillet, tomate, familles: familles);
      final rep = s.whereType<SuggestionBenefique>().firstWhere(
          (x) => x.mecanisme == TypeBeneficeAssociation.repulsionRavageur);
      expect(rep.confiance, NiveauConfiance.eleve);
      expect(rep.slug, 'nematode');
    });

    test('repulsionRavageur: ignoré sans résolveur de familles', () {
      final oeillet =
          _f('oeillet', usages: {UsagePlante.repulsif}, repulsifContre: {'nematode'});
      final tomate = _f('tomate', famille: 'Solanaceae');
      expect(_benefices(moteur.deriver(oeillet, tomate)),
          isNot(contains(TypeBeneficeAssociation.repulsionRavageur)));
    });

    test('plantePiege: piège un ravageur de la famille de B', () {
      final capucine = _f('capucine', piegeA: {'puceron'});
      final feve = _f('feve', famille: 'Fabaceae');
      final familles = _familles([_famille('fabaceae', ravageurs: {'puceron'})]);
      expect(_benefices(moteur.deriver(capucine, feve, familles: familles)),
          contains(TypeBeneficeAssociation.plantePiege));
    });
  });

  group('deriver — règles de conflit', () {
    test('memeFamilleRavageurs: même famille botanique (sans résolveur)', () {
      final a = _f('tomate', famille: 'Solanaceae');
      final b = _f('pomme_de_terre', famille: 'solanaceae');
      expect(_conflits(moteur.deriver(a, b)),
          contains(TypeConflitAssociation.memeFamilleRavageurs));
    });

    test('competitionLumiere: deux hautes qui exigent le plein soleil', () {
      final a = _f('mais', hauteurMax: 200);
      final b = _f('tournesol', hauteurMax: 250);
      expect(_conflits(moteur.deriver(a, b)),
          contains(TypeConflitAssociation.competitionLumiere));
    });

    test('competitionLumiere: PAS de conflit si l une tolère l ombre (ADR-0014)',
        () {
      final a = _f('mais', hauteurMax: 200);
      // Haute mais tolère la mi-ombre → n exige pas le plein soleil → pas de concurrence.
      final b =
          _f('tournesol', hauteurMax: 250, soleilMin: NiveauSoleil.miOmbre);
      expect(_conflits(moteur.deriver(a, b)),
          isNot(contains(TypeConflitAssociation.competitionLumiere)));
    });

    test('competitionAzote: deux gourmandes en azote', () {
      final a = _f('chou', besoinAzote: NiveauBesoin.eleve);
      final b = _f('courge', besoinAzote: NiveauBesoin.eleve);
      expect(_conflits(moteur.deriver(a, b)),
          contains(TypeConflitAssociation.competitionAzote));
    });
  });

  group('deriver — règles ADR-0014 (mécanismes activés)', () {
    test('ameublissementSol: racine pivotante × racine superficielle', () {
      final radis = _f('radis', enracinement: EnracinementPlante.pivotant);
      final laitue = _f('laitue', enracinement: EnracinementPlante.superficiel);
      final s = moteur.deriver(radis, laitue).whereType<SuggestionBenefique>();
      final am = s.firstWhere(
          (x) => x.mecanisme == TypeBeneficeAssociation.ameublissementSol);
      expect(am.criteres, contains(CritereAssociation.sourceRacineProfonde));
    });

    test('attractionAuxiliaires: attire auxiliaires × cible à ravageurs', () {
      final aneth = _f('aneth', usages: {UsagePlante.attireAuxiliaires});
      final chou = _f('chou', famille: 'Brassicaceae');
      final fams = _familles([_famille('brassicaceae', ravageurs: {'piéride'})]);
      final s = moteur
          .deriver(aneth, chou, familles: fams)
          .whereType<SuggestionBenefique>();
      expect(s.map((x) => x.mecanisme),
          contains(TypeBeneficeAssociation.attractionAuxiliaires));
    });

    test('competitionEau: deux forts besoins en eau', () {
      final a = _f('courgette', eau: BesoinEau.eleve);
      final b = _f('concombre', eau: BesoinEau.eleve);
      expect(_conflits(moteur.deriver(a, b)),
          contains(TypeConflitAssociation.competitionEau));
    });

    test('competitionEspace: deux plantes très étalées', () {
      final a = _f('courge', espacementCm: 100);
      final b = _f('potiron', espacementCm: 90);
      expect(_conflits(moteur.deriver(a, b)),
          contains(TypeConflitAssociation.competitionEspace));
    });

    test('successionTemporelle: calendrier décalé avec contexte (ADR-0014)', () {
      FichePlante avecPeriodes(String id, Periode plant, Periode recolte) =>
          FichePlante(
            id: id,
            nomScientifique: '$id sp',
            familleBotanique: 'Test',
            categorie: CategoriePlante.legume,
            usages: const {UsagePlante.alimentaire},
            nomsLocalises: {'fr': id},
            besoins: BesoinsCulture(
                eau: BesoinEau.modere,
                soleil: NiveauSoleil.pleinSoleil,
                phMin: 6,
                phMax: 7),
            espacementCm: 30,
            dureeAvantRecolteJoursMin: 60,
            dureeAvantRecolteJoursMax: 80,
            periodes: {
              Hemisphere.nord: {
                TypeClimat.oceanique:
                    PeriodesCulture(plantation: plant, recolte: recolte),
              },
            },
          );
      // Printemps {3,4,5} vs automne {9,10,11} → occupations disjointes.
      final a = avecPeriodes('printemps', const Periode(3, 3), const Periode(5, 5));
      final b = avecPeriodes('automne', const Periode(9, 9), const Periode(11, 11));
      final s = moteur
          .deriver(a, b,
              hemisphere: Hemisphere.nord, climat: TypeClimat.oceanique)
          .whereType<SuggestionBenefique>()
          .firstWhere(
              (x) => x.mecanisme == TypeBeneficeAssociation.successionTemporelle);
      expect(s.confiance, NiveauConfiance.moyen);
      expect(s.criteres, contains(CritereAssociation.occupationsDecalees));
    });

    test('partageMaladies: familles différentes hôtes d une même maladie', () {
      final fraise = _f('fraise', famille: 'Rosaceae');
      final tomate = _f('tomate', famille: 'Solanaceae');
      final fams = _familles([
        _famille('rosaceae', maladies: {'verticilliose'}),
        _famille('solanaceae', maladies: {'verticilliose'}),
      ]);
      final c = moteur.deriver(fraise, tomate, familles: fams);
      expect(_conflits(c),
          contains(TypeConflitAssociation.partageMaladies));
      // Même famille ne se déclenche pas (familles différentes).
      expect(_conflits(c),
          isNot(contains(TypeConflitAssociation.memeFamilleRavageurs)));
    });

    test('allélopathie n est pas dérivée', () {
      final a = _f('a');
      final b = _f('b');
      expect(_conflits(moteur.deriver(a, b)),
          isNot(contains(TypeConflitAssociation.allelopathie)));
    });
  });

  test('une fiche avec elle-même ne dérive rien', () {
    final a = _f('a', fixeAzote: true, besoinAzote: NiveauBesoin.eleve);
    expect(moteur.deriver(a, a), isEmpty);
  });

  group('suggestionsNouvelles — précédence curatée & fusion', () {
    test('une association bénéfique curatée masque le bénéfice dérivé', () {
      final haricot = _f(
        'haricot',
        fixeAzote: true,
        benefiques: [AssociationBenefique(cibleId: 'mais')],
      );
      final mais = _f('mais', besoinAzote: NiveauBesoin.eleve);
      final s = moteur.suggestionsNouvelles(haricot, [haricot, mais]);
      // The benefit toward mais is curated → no derived benefit suggested.
      expect(
        s.whereType<SuggestionBenefique>().where((x) => x.cibleId == 'mais'),
        isEmpty,
      );
    });

    test('dérive dans les deux sens, relabellisé sur l autre plante', () {
      // mais declares nothing; haricot fixes azote and mais is greedy.
      final mais = _f('mais', besoinAzote: NiveauBesoin.eleve);
      final haricot = _f('haricot', fixeAzote: true);
      final s = moteur.suggestionsNouvelles(mais, [mais, haricot]);
      // From mais' point of view, the benefit (haricot fixes for mais) targets haricot.
      final fix = s.whereType<SuggestionBenefique>().where(
          (x) => x.mecanisme == TypeBeneficeAssociation.fixationAzote);
      expect(fix, isNotEmpty);
      expect(fix.first.cibleId, 'haricot');
    });

    test('exclut la plante centrale elle-même', () {
      final a = _f('a', besoinAzote: NiveauBesoin.eleve, fixeAzote: true);
      final s = moteur.suggestionsNouvelles(a, [a]);
      expect(s, isEmpty);
    });
  });

  group('sens — direction dérivée (ADR-0012)', () {
    // Distinct families everywhere, so no spurious memeFamille conflict.
    SuggestionBenefique benefVers(List<SuggestionAssociation> s, String id) =>
        s.whereType<SuggestionBenefique>().firstWhere((x) => x.cibleId == id);
    SuggestionConflit conflitVers(List<SuggestionAssociation> s, String id) =>
        s.whereType<SuggestionConflit>().firstWhere((x) => x.cibleId == id);

    test('asymétrique: le centre qui fixe l azote DONNE', () {
      final haricot = _f('haricot', famille: 'Fabaceae', fixeAzote: true);
      final mais =
          _f('mais', famille: 'Poaceae', besoinAzote: NiveauBesoin.eleve);
      final s = moteur.suggestionsNouvelles(haricot, [haricot, mais]);
      expect(benefVers(s, 'mais').sens, SensAssociation.donne);
    });

    test('asymétrique: le centre gourmand REÇOIT', () {
      final haricot = _f('haricot', famille: 'Fabaceae', fixeAzote: true);
      final mais =
          _f('mais', famille: 'Poaceae', besoinAzote: NiveauBesoin.eleve);
      final s = moteur.suggestionsNouvelles(mais, [mais, haricot]);
      expect(benefVers(s, 'haricot').sens, SensAssociation.recoit);
    });

    test('symétrique: concurrence azote des deux côtés = MUTUEL', () {
      final chou =
          _f('chou', famille: 'Brassicaceae', besoinAzote: NiveauBesoin.eleve);
      final courge = _f('courge',
          famille: 'Cucurbitaceae', besoinAzote: NiveauBesoin.eleve);
      final s = moteur.suggestionsNouvelles(chou, [chou, courge]);
      expect(conflitVers(s, 'courge').sens, SensAssociation.mutuel);
    });
  });

  group('inventaire des règles (provenance glossaire, ADR-0017)', () {
    // The glossary marks each mechanism page "computed by the engine" vs
    // "documented by the community" from [beneficesDerivables] /
    // [conflitsDerivables]. This scan keeps those declared sets equal to the
    // mechanisms the rules of `deriver` actually emit: a dormant mechanism
    // left marked, or a new rule left unmarked, breaks the suite.
    Set<String> emisPar(String source, String enumName) {
      final sansCommentaires =
          source.replaceAll(RegExp(r'//.*'), '').replaceAll(
              RegExp(r'///.*'), '');
      final corpsDeriver = sansCommentaires
          .substring(sansCommentaires.indexOf('deriver('));
      return RegExp('$enumName\\.(\\w+)')
          .allMatches(corpsDeriver)
          .map((m) => m.group(1)!)
          .toSet();
    }

    late final String source = File(
            'lib/application/engine/moteur_derivation_associations.dart')
        .readAsStringSync();

    test('beneficesDerivables = les bénéfices émis par les règles', () {
      expect(
        MoteurDerivationAssociations.beneficesDerivables
            .map((m) => m.name)
            .toSet(),
        emisPar(source, 'TypeBeneficeAssociation'),
      );
    });

    test('conflitsDerivables = les conflits émis par les règles', () {
      expect(
        MoteurDerivationAssociations.conflitsDerivables
            .map((m) => m.name)
            .toSet(),
        emisPar(source, 'TypeConflitAssociation'),
      );
    });
  });
}
