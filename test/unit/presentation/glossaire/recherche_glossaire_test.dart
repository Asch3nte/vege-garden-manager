import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/glossaire/chapitre_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/recherche_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/terme_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/type_terme_glossaire.dart';

TermeGlossaire _terme(String slug, String titre, String definition) =>
    TermeGlossaire(
      id: TermeGlossaire.idNotion(slug),
      chapitre: ChapitreGlossaire.culturesEtPlantes,
      type: TypeTermeGlossaire.notion,
      titre: titre,
      definition: definition,
    );

void main() {
  group('normaliserRecherche', () {
    test('lowercases and strips accents and ligatures', () {
      expect(normaliserRecherche('Épinard'), 'epinard');
      expect(normaliserRecherche('Œil de paon'), 'oeil de paon');
      expect(normaliserRecherche('MÂCHE  à couper'), 'mache a couper');
    });

    test('trims and collapses whitespace', () {
      expect(normaliserRecherche('  deux   mots '), 'deux mots');
    });
  });

  group('rechercherTermes', () {
    final termes = [
      _terme('rotation', 'Rotation des cultures', 'Changer de place chaque année.'),
      _terme('mildiou', 'Mildiou', 'Maladie favorisée par l’humidité.'),
      _terme('oya', 'Oya', 'Poterie enterrée qui diffuse l’eau et espace la rotation des arrosages.'),
    ];

    test('a blank query returns everything unchanged', () {
      expect(rechercherTermes(termes, '   '), termes);
    });

    test('matches titles case- and accent-insensitively', () {
      expect(rechercherTermes(termes, 'MILDIOU'), [termes[1]]);
    });

    test('title matches rank before definition matches', () {
      // « rotation » appears in the title of the first term and in the
      // definition of « Oya ».
      expect(rechercherTermes(termes, 'rotation'), [termes[0], termes[2]]);
    });

    test('matches inside definitions', () {
      expect(rechercherTermes(termes, 'humidité'), [termes[1]]);
    });

    test('no match yields an empty list', () {
      expect(rechercherTermes(termes, 'courgette'), isEmpty);
    });

    test('the result list is unmodifiable', () {
      expect(
        () => rechercherTermes(termes, 'oya').clear(),
        throwsUnsupportedError,
      );
    });
  });
}
