import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/type_bioagresseur.dart';
import 'package:pot_a_gerer/l10n/app_localizations_fr.dart';
import 'package:pot_a_gerer/presentation/glossaire/chapitre_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/complement_terme.dart';
import 'package:pot_a_gerer/presentation/glossaire/liens_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/registre_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/terme_glossaire.dart';
import 'package:pot_a_gerer/presentation/glossaire/type_terme_glossaire.dart';

final _l10n = AppLocalizationsFr();

FamilleBotanique _famille(
  String id, {
  String? description,
  Set<String> maladies = const {},
  Set<String> ravageurs = const {},
}) =>
    FamilleBotanique(
      id: id,
      nomScientifique: id[0].toUpperCase() + id.substring(1),
      categories: {CategoriePlante.legume},
      nomsLocalises: {'fr': 'Nom fr de $id'},
      descriptionsLocalisees:
          description == null ? null : {'fr': description},
      maladiesCommunes: maladies,
      ravageursCommuns: ravageurs,
    );

Bioagresseur _bio(String id, TypeBioagresseur type, {String? description}) =>
    Bioagresseur(
      id: id,
      type: type,
      nomsLocalises: {'fr': 'Nom fr de $id'},
      descriptionsLocalisees:
          description == null ? null : {'fr': description},
    );

void main() {
  group('construireGlossaire', () {
    final familles = [
      _famille('solanaceae',
          description: 'La famille des tomates.',
          maladies: {'mildiou'},
          ravageurs: {'doryphore'}),
      _famille('fabaceae'), // no description → ARB fallback
    ];
    final bioagresseurs = [
      _bio('mildiou', TypeBioagresseur.maladie, description: 'Champignon.'),
      _bio('doryphore', TypeBioagresseur.ravageur),
    ];

    List<TermeGlossaire> construire() => construireGlossaire(
        l10n: _l10n, familles: familles, bioagresseurs: bioagresseurs);

    test('derives one prefixed term per family and per bioaggressor', () {
      final ids = construire().map((t) => t.id);
      expect(
        ids,
        containsAll([
          'famille.solanaceae',
          'famille.fabaceae',
          'bio.mildiou',
          'bio.doryphore',
        ]),
      );
    });

    test('ids are unique (indexable)', () {
      final index = indexerParId(construire());
      expect(index.length, construire().length);
    });

    test('family terms carry localized title, description and family block',
        () {
      final terme = indexerParId(construire())['famille.solanaceae']!;
      expect(terme.chapitre, ChapitreGlossaire.famillesBotaniques);
      expect(terme.type, TypeTermeGlossaire.famille);
      expect(terme.titre, 'Nom fr de solanaceae');
      expect(terme.definition, 'La famille des tomates.');
      final bloc = terme.complements.whereType<ComplementFamille>().single;
      expect(bloc.famille.id, 'solanaceae');
      expect(bloc.idsMaladies, ['bio.mildiou']);
      expect(bloc.idsRavageurs, ['bio.doryphore']);
    });

    test('a reference without description gets the explicit ARB fallback', () {
      final index = indexerParId(construire());
      expect(index['famille.fabaceae']!.definition,
          _l10n.glossaireDefinitionAVenir);
      expect(index['bio.doryphore']!.definition,
          _l10n.glossaireDefinitionAVenir);
    });

    test('bioaggressor type maps to the maladie/ravageur term kind', () {
      final index = indexerParId(construire());
      expect(index['bio.mildiou']!.type, TypeTermeGlossaire.maladie);
      expect(index['bio.doryphore']!.type, TypeTermeGlossaire.ravageur);
      expect(index['bio.mildiou']!.chapitre, ChapitreGlossaire.santeDuJardin);
    });

    test('bioaggressor terms link back to every referencing family (inverse)',
        () {
      final bloc = indexerParId(construire())['bio.mildiou']!
          .complements
          .whereType<ComplementBioagresseur>()
          .single;
      expect(bloc.idsFamilles, ['famille.solanaceae']);
    });

    test('families and bioaggressors are sorted by normalized title', () {
      final termes = construire();
      final titresFamilles = [
        for (final t in termes)
          if (t.type == TypeTermeGlossaire.famille) t.titre,
      ];
      expect(titresFamilles, ['Nom fr de fabaceae', 'Nom fr de solanaceae']);
    });

    test('seed notions are present and filed in their chapters', () {
      final index = indexerParId(construire());
      expect(index['notion.famille-botanique']!.chapitre,
          ChapitreGlossaire.famillesBotaniques);
      expect(index['notion.rotation-cultures']!.chapitre,
          ChapitreGlossaire.famillesBotaniques);
      expect(index['notion.compagnonnage']!.chapitre,
          ChapitreGlossaire.associationsEtCompagnonnage);
      expect(index['notion.compagnonnage']!.astuce, isNotEmpty);
      expect(index['notion.compagnonnage']!.conseils, isNotEmpty);
    });

    test('every wiki link of every term resolves (integrity, D6 seed)', () {
      final termes = construire();
      final index = indexerParId(termes);
      for (final terme in termes) {
        for (final texte in [terme.definition, ...terme.conseils]) {
          for (final id in extraireIdsLiens(texte)) {
            expect(index, contains(id),
                reason: 'lien [[$id]] du terme ${terme.id} sans cible');
          }
        }
      }
    });

    test('the glossary list is unmodifiable', () {
      expect(() => construire().clear(), throwsUnsupportedError);
    });
  });

  group('indexerParId', () {
    test('throws on duplicated ids', () {
      final terme = TermeGlossaire(
        id: TermeGlossaire.idNotion('x'),
        chapitre: ChapitreGlossaire.culturesEtPlantes,
        type: TypeTermeGlossaire.notion,
        titre: 'X',
        definition: 'Définition.',
      );
      expect(() => indexerParId([terme, terme]), throwsArgumentError);
    });
  });
}
