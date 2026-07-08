import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/modele_fiche_personnelle.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_mapper.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_validator.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/serialiseur_fiche_personnelle.dart';
import 'package:yaml/yaml.dart';

ModeleFichePersonnelle modele({
  String nomCommunFr = 'Tomate de mémé',
  String? nomCommunEn,
  String? descriptionFr,
  CategoriePlante categorie = CategoriePlante.legume,
  SousTypeLegume? sousType = SousTypeLegume.legumeFruit,
  double phMin = 6,
  double phMax = 7.5,
  int? difficulte,
}) =>
    ModeleFichePersonnelle(
      idFiche: 'perso_tomate_meme',
      categorie: categorie,
      sousType: sousType,
      usages: {UsagePlante.alimentaire, UsagePlante.compagnonnage},
      nomScientifique: 'Solanum lycopersicum',
      familleBotanique: 'solanaceae',
      nomCommunFr: nomCommunFr,
      nomCommunEn: nomCommunEn,
      descriptionFr: descriptionFr,
      ensoleillement: NiveauSoleil.pleinSoleil,
      arrosage: BesoinEau.modere,
      qualitesSol: {QualiteSol.riche, QualiteSol.bienDraine},
      phMin: phMin,
      phMax: phMax,
      espacementCm: 40,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 90,
      difficulte: difficulte,
    );

void main() {
  const serialiseur = SerialiseurFichePersonnelle();
  // Personal ids use their own namespace, not the canonical catalogue format.
  const validator = FichePlanteValidator(validerFormatId: false);
  const mapper = FichePlanteMapper();

  YamlMap parse(ModeleFichePersonnelle m) =>
      loadYaml(serialiseur.versYaml(m)) as YamlMap;

  test('emitted YAML passes the catalogue validator', () {
    final map = parse(modele(descriptionFr: 'Ma variété familiale.'));
    expect(() => validator.valider(map, source: 'perso'), returnsNormally);
  });

  test('emitted YAML maps into a FichePlante exploitable by the engines', () {
    final fiche = mapper.versEntite(
        parse(modele(nomCommunEn: 'Granny tomato', difficulte: 2)));
    expect(fiche.id, 'perso_tomate_meme');
    expect(fiche.nomScientifique, 'Solanum lycopersicum');
    expect(fiche.familleBotanique, 'solanaceae');
    expect(fiche.categorie, CategoriePlante.legume);
    expect(fiche.sousType, SousTypeLegume.legumeFruit);
    expect(fiche.usages,
        {UsagePlante.alimentaire, UsagePlante.compagnonnage});
    expect(fiche.nomsLocalises['fr'], 'Tomate de mémé');
    expect(fiche.nomsLocalises['en'], 'Granny tomato');
    expect(fiche.besoins.eau, BesoinEau.modere);
    expect(fiche.besoins.soleil, NiveauSoleil.pleinSoleil);
    expect(fiche.besoins.qualitesSol,
        {QualiteSol.riche, QualiteSol.bienDraine});
    expect(fiche.besoins.phMin, 6);
    expect(fiche.besoins.phMax, 7.5);
    expect(fiche.espacementCm, 40);
    expect(fiche.dureeAvantRecolteJoursMin, 60);
    expect(fiche.dureeAvantRecolteJoursMax, 90);
    expect(fiche.difficulte, 2);
  });

  test('optional fields are omitted when unset', () {
    final map = parse(modele());
    expect(map.containsKey('difficulte'), isFalse);
    expect((map['i18n'] as Map).containsKey('en'), isFalse);
    expect((map['i18n']['fr'] as Map).containsKey('description'), isFalse);
    expect(map.containsKey('sous_type'), isTrue);
  });

  test('drops sous_type for a non-legume categorie', () {
    final map = parse(modele(categorie: CategoriePlante.fleur, sousType: null));
    expect(map.containsKey('sous_type'), isFalse);
    expect(() => validator.valider(map, source: 'perso'), returnsNormally);
  });

  test('round-trips through depuisMap', () {
    final source = modele(
        nomCommunEn: 'Granny tomato',
        descriptionFr: 'Ma variété.',
        difficulte: 3);
    final rebuilt = serialiseur.depuisMap(parse(source));
    expect(rebuilt.idFiche, source.idFiche);
    expect(rebuilt.categorie, source.categorie);
    expect(rebuilt.sousType, source.sousType);
    expect(rebuilt.usages, source.usages);
    expect(rebuilt.nomCommunFr, source.nomCommunFr);
    expect(rebuilt.nomCommunEn, source.nomCommunEn);
    expect(rebuilt.descriptionFr, source.descriptionFr);
    expect(rebuilt.qualitesSol, source.qualitesSol);
    expect(rebuilt.phMin, source.phMin);
    expect(rebuilt.phMax, source.phMax);
    expect(rebuilt.difficulte, source.difficulte);
  });

  test('escapes hostile free text so the YAML stays parseable', () {
    final nasty = 'Tomate: "grand-mère"\nligne 2\tbackslash \\ end';
    final rebuilt = serialiseur.depuisMap(
        parse(modele(nomCommunFr: nasty, descriptionFr: nasty)));
    expect(rebuilt.nomCommunFr, nasty);
    // description is trimmed of surrounding whitespace on read
    expect(rebuilt.descriptionFr, nasty.trim());
  });

  test('integral pH values round-trip without spurious decimals', () {
    final map = parse(modele(phMin: 6, phMax: 7));
    expect(map['besoins']['ph_min'], 6);
    expect(map['besoins']['ph_max'], 7);
  });
}
