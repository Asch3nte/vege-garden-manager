import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/charge_tuteur.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/phase_sensible_eau.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/type_benefice_association.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_conflit_association.dart';
import 'package:pot_a_gerer/domain/enums/enracinement_plante.dart';
import 'package:pot_a_gerer/domain/enums/groupe_cultural.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/precedent_cultural.dart';
import 'package:pot_a_gerer/domain/exceptions/fiche_plante_invalide_exception.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_yaml_parser.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_mapper.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_validator.dart';

const _parser = CatalogueYamlParser();
const _validator = FichePlanteValidator();
const _mapper = FichePlanteMapper();

void main() {
  group('Catalogue pipeline — golden file LEG-001.yaml', () {
    final contenu =
        File('assets/fiches_plantes/legumes/LEG-001.yaml').readAsStringSync();
    final map = _parser.parser(contenu, source: 'LEG-001.yaml');

    test('the golden sheet passes validation', () {
      expect(() => _validator.valider(map, source: 'LEG-001.yaml'),
          returnsNormally);
    });

    test('maps to a coherent FichePlante', () {
      final f = _mapper.versEntite(map);
      expect(f.id, 'LEG-001');
      expect(f.categorie, CategoriePlante.legume);
      expect(f.sousType, SousTypeLegume.legumeFruit);
      expect(f.usages, {UsagePlante.alimentaire});
      expect(f.nomLocalise('fr'), 'Tomate');
      expect(f.nomLocalise('en'), 'Tomato');
      expect(f.besoins.eau, BesoinEau.eleve);
      expect(f.besoins.soleil, NiveauSoleil.pleinSoleil);
      expect(f.besoins.phMin, 6.0);
      expect(f.besoins.phMax, 7.0);
      expect(f.espacementCm, 60);
      expect(f.dureeAvantRecolteJoursMin, 70);
      expect(f.dureeAvantRecolteJoursMax, 90);
      expect(f.rotationFamille, 'solanaceae');
      expect(f.delaiRetourAnnees, 4);
    });

    test('maps the cultural precedents (rotation avancée)', () {
      final f = _mapper.versEntite(map);
      // LEG-001: precedents_favorables: [legumineuses, engrais_verts]
      expect(f.precedentsFavorables, {
        const PrecedentCultural.groupe(GroupeCultural.legumineuses),
        const PrecedentCultural.groupe(GroupeCultural.engraisVerts),
      });
      // precedents_defavorables: [solanaceae]
      expect(f.precedentsDefavorables,
          {PrecedentCultural.famille('solanaceae')});
    });

    test('maps the periods (hemisphere × climate)', () {
      final f = _mapper.versEntite(map);
      expect(
        f.estPlantableEn(
            DateTime(2026, 5, 15), Hemisphere.nord, TypeClimat.oceanique),
        isTrue,
      );
      expect(
        f.estPlantableEn(
            DateTime(2026, 12, 1), Hemisphere.nord, TypeClimat.oceanique),
        isFalse,
      );
      expect(
        f.periodesPour(Hemisphere.nord, TypeClimat.mediterraneen),
        isNotNull,
      );
    });

    test('maps associations by canonical mother id', () {
      final f = _mapper.versEntite(map);
      expect(f.sAssocieBienAvec('ARO-001'), isTrue); // basilic → ARO-001
      expect(f.sAssocieBienAvec('FLE-002'), isTrue); // souci → FLE-002
      expect(f.entreEnConflitAvec('LEG-024'), isTrue); // fenouil → LEG-024
      expect(f.entreEnConflitAvec('LEG-020'), isTrue); // pomme de terre → LEG-020
      expect(f.sAssocieBienAvec('LEG-024'), isFalse);
    });
  });

  group('Catalogue pipeline — cultural precedents normalization (Lot 2)', () {
    const yamlPrecedents = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
rotation:
  famille: solanaceae
  delai_retour_annees: 4
  precedents_favorables: [legumineuses, cucurbitacees, "graminées"]
  precedents_defavorables: [ail, "", solanaceae]
''';

    test('normalizes spelling drift and skips blank entries', () {
      final m = _parser.parser(yamlPrecedents, source: 'x');
      final f = _mapper.versEntite(m);
      expect(f.precedentsFavorables, {
        const PrecedentCultural.groupe(GroupeCultural.legumineuses),
        PrecedentCultural.famille('cucurbitaceae'), // cucurbitacees →
        PrecedentCultural.famille('poaceae'), // graminées →
      });
      // "ail" → amaryllidaceae, blank skipped, solanaceae kept.
      expect(f.precedentsDefavorables, {
        PrecedentCultural.famille('amaryllidaceae'),
        PrecedentCultural.famille('solanaceae'),
      });
    });

    test('a sheet without a rotation block carries empty precedent sets', () {
      const bare = '''
id: y
nom_scientifique: Y y
famille_botanique: Yaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: Y
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final f = _mapper.versEntite(_parser.parser(bare, source: 'y'));
      expect(f.precedentsFavorables, isEmpty);
      expect(f.precedentsDefavorables, isEmpty);
    });
  });

  group('Catalogue pipeline — typed associations (ADR-0010)', () {
    const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
associations:
  beneficies:
    - id: LEG-002
      type: fixation_azote
      raison_i18n: { fr: "Enrichit le sol", en: "Enriches the soil" }
    - id: LEG-003
  defavorables:
    - id: LEG-004
      type: meme_famille_ravageurs
''';
    final map = _parser.parser(yaml, source: 'x');

    test('passes validation with typed mechanisms', () {
      expect(() => _validator.valider(map, source: 'x'), returnsNormally);
    });

    test('loads the mechanism and the localised reason', () {
      final f = _mapper.versEntite(map);
      final assoc = f.associationBenefiqueAvec('LEG-002')!;
      expect(assoc.mecanisme, TypeBeneficeAssociation.fixationAzote);
      expect(assoc.raison('fr'), 'Enrichit le sol');
      expect(assoc.raison('en'), 'Enriches the soil');
      // Unknown locale falls back to French.
      expect(assoc.raison('es'), 'Enrichit le sol');

      final conflit = f.associationConflitAvec('LEG-004')!;
      expect(conflit.mecanisme, TypeConflitAssociation.memeFamilleRavageurs);
      expect(conflit.aRaison, isFalse);
    });

    test('a bare association keeps the relation with no mechanism/reason', () {
      final f = _mapper.versEntite(map);
      final assoc = f.associationBenefiqueAvec('LEG-003')!;
      expect(f.sAssocieBienAvec('LEG-003'), isTrue);
      expect(assoc.mecanisme, isNull);
      expect(assoc.mecanismes, isEmpty);
      expect(assoc.raison('fr'), isNull);
    });

    test('a type given as a list loads several mechanisms (ADR-0012)', () {
      const yamlListe = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
associations:
  beneficies:
    - id: LEG-009
      type: [brouillage_olfactif, repulsion_ravageur]
''';
      final m = _parser.parser(yamlListe, source: 'x');
      expect(() => _validator.valider(m, source: 'x'), returnsNormally);
      final assoc = _mapper.versEntite(m).associationBenefiqueAvec('LEG-009')!;
      expect(assoc.mecanismes, {
        TypeBeneficeAssociation.brouillageOlfactif,
        TypeBeneficeAssociation.repulsionRavageur,
      });
    });

    test('loads the ADR-0013 mechanisms from their snake_case tokens', () {
      const yamlAdr13 = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
associations:
  beneficies:
    - id: LEG-002
      type: attraction_auxiliaires
    - id: LEG-003
      type: ameublissement_sol
  defavorables:
    - id: LEG-004
      type: competition_eau
    - id: LEG-005
      type: competition_espace
    - id: LEG-006
      type: partage_maladies
''';
      final m = _parser.parser(yamlAdr13, source: 'x');
      expect(() => _validator.valider(m, source: 'x'), returnsNormally);
      final f = _mapper.versEntite(m);
      expect(f.associationBenefiqueAvec('LEG-002')!.mecanisme,
          TypeBeneficeAssociation.attractionAuxiliaires);
      expect(f.associationBenefiqueAvec('LEG-003')!.mecanisme,
          TypeBeneficeAssociation.ameublissementSol);
      expect(f.associationConflitAvec('LEG-004')!.mecanisme,
          TypeConflitAssociation.competitionEau);
      expect(f.associationConflitAvec('LEG-005')!.mecanisme,
          TypeConflitAssociation.competitionEspace);
      expect(f.associationConflitAvec('LEG-006')!.mecanisme,
          TypeConflitAssociation.partageMaladies);
    });

    test('loads enracinement and the attire_auxiliaires usage (ADR-0014)', () {
      const yamlA14 = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: aromatique
usages: [condimentaire, attire_auxiliaires]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
  enracinement: pivotant
''';
      final m = _parser.parser(yamlA14, source: 'x');
      expect(() => _validator.valider(m, source: 'x'), returnsNormally);
      final f = _mapper.versEntite(m);
      expect(f.enracinement, EnracinementPlante.pivotant);
      expect(f.aUsage(UsagePlante.attireAuxiliaires), isTrue);
    });

    test('rejects an unknown enracinement (ADR-0014)', () {
      const mauvais = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
  enracinement: tres_profond
''';
      final m = _parser.parser(mauvais, source: 'x');
      expect(() => _validator.valider(m, source: 'x'), throwsA(anything));
    });

    test('rejects an unknown mechanism inside a type list', () {
      const mauvais = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
associations:
  beneficies:
    - id: LEG-009
      type: [fixation_azote, mecanisme_bidon]
''';
      final m = _parser.parser(mauvais, source: 'x');
      expect(() => _validator.valider(m, source: 'x'),
          throwsA(isA<FichePlanteInvalideException>()));
    });
  });

  group('Catalogue pipeline — targeted defence (ADR-0010 Lot 2)', () {
    const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire, repulsif]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
  charge_tuteur: legere
  hauteur_adulte_cm: [40, 60]
repulsif_contre: [nematode, puceron]
piege_a: [puceron]
''';
    final map = _parser.parser(yaml, source: 'x');

    test('passes validation', () {
      expect(() => _validator.valider(map, source: 'x'), returnsNormally);
    });

    test('loads the defence slugs, support load and adult height', () {
      final f = _mapper.versEntite(map);
      expect(f.repulsifContre, {'nematode', 'puceron'});
      expect(f.piegeA, {'puceron'});
      expect(f.repousse('nematode'), isTrue);
      expect(f.piege('puceron'), isTrue);
      expect(f.chargeTuteur, ChargeTuteur.legere);
      expect(f.hauteurAdulteCmMin, 40);
      expect(f.hauteurAdulteCmMax, 60);
    });

    test('rejects an unknown charge_tuteur', () {
      const mauvais = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
  charge_tuteur: enorme
''';
      final m = _parser.parser(mauvais, source: 'x');
      expect(() => _validator.valider(m, source: 'x'),
          throwsA(isA<FichePlanteInvalideException>()));
    });
  });

  group('Catalogue pipeline — detailed watering (ADR-0009 eauDetaillee)', () {
    final goldenMap = _parser.parser(
      File('assets/fiches_plantes/legumes/LEG-001.yaml').readAsStringSync(),
      source: 'LEG-001.yaml',
    );

    test('the golden LEG-001 carries sensitive stages and a note', () {
      final f = _mapper.versEntite(goldenMap);
      final d = f.besoins.arrosageDetaille;
      expect(d, isNotNull);
      expect(d!.phasesSensibles, {
        PhaseSensibleEau.floraison,
        PhaseSensibleEau.fructification,
      });
      expect(d.aNote, isTrue);
      expect(d.note('fr'), contains('cul noir'));
      // Seeded fiches deliberately carry no invented figures.
      expect(d.aFrequence, isFalse);
      expect(d.aVolume, isFalse);
    });

    test('a sheet without the block carries no detail', () {
      const bare = '''
id: y
nom_scientifique: Y y
famille_botanique: Yaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: Y
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final f = _mapper.versEntite(_parser.parser(bare, source: 'y'));
      expect(f.besoins.arrosageDetaille, isNull);
      expect(f.besoins.aArrosageDetaille, isFalse);
    });

    test('parses frequency, volume, stages and a localised note', () {
      const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
  arrosage_detaille:
    frequence_jours: [2, 3]
    volume_litres_m2: [3, 5.5]
    phases_sensibles: [floraison, fructification]
    note_i18n: { fr: "Arrosez au pied.", en: "Water at the base." }
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final m = _parser.parser(yaml, source: 'x');
      expect(() => _validator.valider(m, source: 'x'), returnsNormally);
      final d = _mapper.versEntite(m).besoins.arrosageDetaille!;
      expect(d.frequenceJoursMin, 2);
      expect(d.frequenceJoursMax, 3);
      expect(d.volumeLitresM2Min, 3.0);
      expect(d.volumeLitresM2Max, 5.5);
      expect(d.phasesSensibles,
          {PhaseSensibleEau.floraison, PhaseSensibleEau.fructification});
      expect(d.note('en'), 'Water at the base.');
      expect(d.note('es'), 'Arrosez au pied.'); // fallback
    });

    test('rejects a single frequency bound', () {
      const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
  arrosage_detaille:
    frequence_jours: [2]
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final m = _parser.parser(yaml, source: 'x');
      expect(() => _validator.valider(m, source: 'x'),
          throwsA(isA<FichePlanteInvalideException>()));
    });

    test('rejects an unknown sensitive stage', () {
      const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
  arrosage_detaille:
    phases_sensibles: [maturation]
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final m = _parser.parser(yaml, source: 'x');
      expect(() => _validator.valider(m, source: 'x'),
          throwsA(isA<FichePlanteInvalideException>()));
    });

    test('rejects an empty detail block', () {
      const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
  arrosage_detaille:
    frequence_jours:
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final m = _parser.parser(yaml, source: 'x');
      expect(() => _validator.valider(m, source: 'x'),
          throwsA(isA<FichePlanteInvalideException>()));
    });
  });

  group('Catalogue pipeline — validation failures', () {
    test('rejects a sheet without the French name', () {
      const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  en:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final map = _parser.parser(yaml, source: 'x');
      expect(
        () => _validator.valider(map, source: 'x'),
        throwsA(isA<FichePlanteInvalideException>()),
      );
    });

    test('rejects an inverted pH window', () {
      const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 7.5
  ph_max: 6.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final map = _parser.parser(yaml, source: 'x');
      expect(
        () => _validator.valider(map, source: 'x'),
        throwsA(isA<FichePlanteInvalideException>()),
      );
    });

    test('rejects a non-mapping root', () {
      expect(
        () => _parser.parser('- just\n- a\n- list', source: 'x'),
        throwsA(isA<FichePlanteInvalideException>()),
      );
    });

    test('rejects a variety whose id is not prefixed by its parent_id', () {
      const yaml = '''
id: LEG-002-V001
parent_id: LEG-001
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final map = _parser.parser(yaml, source: 'x');
      expect(
        () => _validator.valider(map, source: 'x'),
        throwsA(isA<FichePlanteInvalideException>()),
      );
    });

    test('formatIdValide recognises the canonical ADR-0005 format', () {
      expect(FichePlanteValidator.formatIdValide('LEG-001'), isTrue);
      expect(FichePlanteValidator.formatIdValide('LEG-001-V001'), isTrue);
      expect(FichePlanteValidator.formatIdValide('ARO-001'), isTrue);
      expect(FichePlanteValidator.formatIdValide('carotte'), isFalse);
      expect(FichePlanteValidator.formatIdValide('leg-001'), isFalse);
      expect(FichePlanteValidator.formatIdValide('LEG-1'), isFalse);
    });

    test('the format check is off by default but rejects legacy ids when on',
        () {
      const yaml = '''
id: carotte
nom_scientifique: Daucus carota
famille_botanique: Apiaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: Carotte
besoins:
  ensoleillement: plein_soleil
  arrosage: modere
  qualites_sol: [leger]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 8
  duree_avant_recolte_jours: [90, 120]
''';
      final map = _parser.parser(yaml, source: 'x');
      // Default validator tolerates the legacy id (migration window).
      expect(() => _validator.valider(map, source: 'x'), returnsNormally);
      // With enforcement on, the legacy id is rejected.
      expect(
        () => const FichePlanteValidator(validerFormatId: true)
            .valider(map, source: 'x'),
        throwsA(isA<FichePlanteInvalideException>()),
      );
    });

    test('rejects an unknown association mechanism (type)', () {
      const yaml = '''
id: x
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
associations:
  beneficies:
    - id: LEG-002
      type: mecanisme_bidon
''';
      final map = _parser.parser(yaml, source: 'x');
      expect(
        () => _validator.valider(map, source: 'x'),
        throwsA(isA<FichePlanteInvalideException>()),
      );
    });

    test('accepts a variety whose id is prefixed by its parent_id', () {
      const yaml = '''
id: LEG-001-V001
parent_id: LEG-001
nom_scientifique: X x
famille_botanique: Xaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: X
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 30
  duree_avant_recolte_jours: [60, 80]
''';
      final map = _parser.parser(yaml, source: 'x');
      expect(
        () => _validator.valider(map, source: 'x'),
        returnsNormally,
      );
    });
  });
}
