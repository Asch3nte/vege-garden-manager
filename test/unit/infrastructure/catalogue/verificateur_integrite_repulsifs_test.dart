import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_bioagresseur.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/verificateur_integrite_repulsifs.dart';

FichePlante _fiche({
  Set<String> repulsifContre = const {},
  Set<String> piegeA = const {},
}) =>
    FichePlante(
      id: 'LEG-001',
      nomScientifique: 'X x',
      familleBotanique: 'Xaceae',
      categorie: CategoriePlante.legume,
      usages: const {UsagePlante.repulsif},
      nomsLocalises: const {'fr': 'X'},
      besoins: BesoinsCulture(
        eau: BesoinEau.modere,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: 40,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 80,
      repulsifContre: repulsifContre,
      piegeA: piegeA,
    );

BioagresseurCache _reference() => BioagresseurCache([
      Bioagresseur(
          id: 'mildiou',
          type: TypeBioagresseur.maladie,
          nomsLocalises: const {'fr': 'Mildiou'}),
      Bioagresseur(
          id: 'puceron',
          type: TypeBioagresseur.ravageur,
          nomsLocalises: const {'fr': 'Puceron'}),
    ]);

void main() {
  const verif = VerificateurIntegriteRepulsifs();

  test('coherent slugs report no problem', () {
    final problemes = verif.verifier(
      [
        _fiche(repulsifContre: {'mildiou', 'puceron'}, piegeA: {'puceron'})
      ],
      _reference(),
    );
    expect(problemes, isEmpty);
  });

  test('flags a repulsif_contre slug missing from the reference', () {
    final problemes =
        verif.verifier([_fiche(repulsifContre: {'inconnu'})], _reference());
    expect(problemes, hasLength(1));
    expect(problemes.first.espece, 'LEG-001');
    expect(problemes.first.raison, contains('repulsif_contre'));
  });

  test('flags a piege_a slug missing from the reference', () {
    final problemes =
        verif.verifier([_fiche(piegeA: {'inconnu'})], _reference());
    expect(problemes, hasLength(1));
    expect(problemes.first.raison, contains('piege_a'));
  });

  test('flags a trapped slug that is a disease, not a pest', () {
    final problemes =
        verif.verifier([_fiche(piegeA: {'mildiou'})], _reference());
    expect(problemes, hasLength(1));
    expect(problemes.first.raison, contains('not a ravageur'));
  });

  test('a repelled disease is accepted (either type may be repelled)', () {
    final problemes =
        verif.verifier([_fiche(repulsifContre: {'mildiou'})], _reference());
    expect(problemes, isEmpty);
  });
}
