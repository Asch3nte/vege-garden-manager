import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/moteur_derivation_associations.dart';
import 'package:pot_a_gerer/application/engine/suggestion_association.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/charge_tuteur.dart';
import 'package:pot_a_gerer/domain/enums/niveau_besoin.dart';
import 'package:pot_a_gerer/domain/enums/niveau_confiance.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/sens_association.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/type_benefice_association.dart';
import 'package:pot_a_gerer/domain/enums/type_conflit_association.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/association_benefique.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';

FichePlante _f(
  String id, {
  String famille = 'Test',
  CategoriePlante categorie = CategoriePlante.legume,
  SousTypeLegume? sousType,
  Set<UsagePlante> usages = const {UsagePlante.alimentaire},
  NiveauSoleil soleil = NiveauSoleil.pleinSoleil,
  NiveauSoleil? soleilMin,
  int dureeMin = 60,
  int dureeMax = 80,
  bool cultureVerticale = false,
  ChargeTuteur? chargeTuteur,
  bool fixeAzote = false,
  NiveauBesoin? besoinAzote,
  int? hauteurMax,
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
        eau: BesoinEau.modere,
        soleil: soleil,
        soleilMin: soleilMin,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: 40,
      dureeAvantRecolteJoursMin: dureeMin,
      dureeAvantRecolteJoursMax: dureeMax,
      cultureVerticale: cultureVerticale,
      chargeTuteur: chargeTuteur,
      fixeAzote: fixeAzote,
      besoinAzote: besoinAzote,
      hauteurAdulteCmMax: hauteurMax,
      repulsifContre: repulsifContre,
      piegeA: piegeA,
      associationsBenefiques: benefiques,
    );

/// Resolver over a few families keyed by normalised name.
ResolveurFamille _familles(List<FamilleBotanique> familles) {
  final parCle = {for (final f in familles) f.id: f};
  return (brute) => parCle[FamilleBotanique.normaliserCle(brute)];
}

FamilleBotanique _famille(String id, {Set<String> ravageurs = const {}}) =>
    FamilleBotanique(
      id: id,
      nomScientifique: id,
      categories: const {CategoriePlante.legume},
      nomsLocalises: {'fr': id},
      ravageursCommuns: ravageurs,
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

    test('etagementLumiere: plante haute en plein soleil × tolère l ombre', () {
      final mais = _f('mais', hauteurMax: 200);
      final laitue = _f('laitue', soleilMin: NiveauSoleil.miOmbre);
      expect(_benefices(moteur.deriver(mais, laitue)),
          contains(TypeBeneficeAssociation.etagementLumiere));
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

    test('competitionLumiere: deux hautes en plein soleil', () {
      final a = _f('mais', hauteurMax: 200);
      final b = _f('tournesol', hauteurMax: 250);
      expect(_conflits(moteur.deriver(a, b)),
          contains(TypeConflitAssociation.competitionLumiere));
    });

    test('competitionAzote: deux gourmandes en azote', () {
      final a = _f('chou', besoinAzote: NiveauBesoin.eleve);
      final b = _f('courge', besoinAzote: NiveauBesoin.eleve);
      expect(_conflits(moteur.deriver(a, b)),
          contains(TypeConflitAssociation.competitionAzote));
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
}
