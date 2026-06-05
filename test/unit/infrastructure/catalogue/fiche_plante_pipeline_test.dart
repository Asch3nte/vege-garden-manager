import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/exceptions/fiche_plante_invalide_exception.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_yaml_parser.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_mapper.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_validator.dart';

const _parser = CatalogueYamlParser();
const _validator = FichePlanteValidator();
const _mapper = FichePlanteMapper();

void main() {
  group('Catalogue pipeline — golden file tomate.yaml', () {
    final contenu =
        File('assets/fiches_plantes/legumes/tomate.yaml').readAsStringSync();
    final map = _parser.parser(contenu, source: 'tomate.yaml');

    test('the golden sheet passes validation', () {
      expect(() => _validator.valider(map, source: 'tomate.yaml'),
          returnsNormally);
    });

    test('maps to a coherent FichePlante', () {
      final f = _mapper.versEntite(map);
      expect(f.id, 'tomate');
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

    test('maps associations by id', () {
      final f = _mapper.versEntite(map);
      expect(f.sAssocieBienAvec('basilic'), isTrue);
      expect(f.sAssocieBienAvec('soucis'), isTrue);
      expect(f.entreEnConflitAvec('fenouil'), isTrue);
      expect(f.entreEnConflitAvec('pomme_de_terre'), isTrue);
      expect(f.sAssocieBienAvec('fenouil'), isFalse);
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
  });
}
