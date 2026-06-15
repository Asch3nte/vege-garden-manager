import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/type_bioagresseur.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/verificateur_integrite_bioagresseurs.dart';

FamilleBotanique _famille({
  Set<String> maladies = const {},
  Set<String> ravageurs = const {},
}) =>
    FamilleBotanique(
      id: 'solanaceae',
      nomScientifique: 'Solanaceae',
      categories: {CategoriePlante.legume},
      nomsLocalises: const {'fr': 'Solanacées'},
      maladiesCommunes: maladies,
      ravageursCommuns: ravageurs,
    );

BioagresseurCache _reference() => BioagresseurCache([
      Bioagresseur(
          id: 'mildiou',
          type: TypeBioagresseur.maladie,
          nomsLocalises: const {'fr': 'Mildiou'}),
      Bioagresseur(
          id: 'doryphore',
          type: TypeBioagresseur.ravageur,
          nomsLocalises: const {'fr': 'Doryphore'}),
    ]);

void main() {
  const verif = VerificateurIntegriteBioagresseurs();

  test('coherent family slugs report no problem', () {
    final problemes = verif.verifier(
      [
        _famille(maladies: {'mildiou'}, ravageurs: {'doryphore'})
      ],
      _reference(),
    );
    expect(problemes, isEmpty);
  });

  test('flags a slug missing from the reference', () {
    final problemes = verif.verifier(
      [
        _famille(maladies: {'inconnue'})
      ],
      _reference(),
    );
    expect(problemes, hasLength(1));
    expect(problemes.first.famille, 'solanaceae');
  });

  test('flags a type mismatch (a pest listed under diseases)', () {
    final problemes = verif.verifier(
      [
        _famille(maladies: {'doryphore'})
      ],
      _reference(),
    );
    expect(problemes, hasLength(1));
    expect(problemes.first.raison, contains('not a maladie'));
  });
}
