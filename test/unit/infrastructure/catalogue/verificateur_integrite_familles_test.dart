import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/groupe_cultural.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/precedent_cultural.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_cache.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/verificateur_integrite_familles.dart';

FichePlante _espece({
  String id = 'LEG-001',
  String familleBotanique = 'Solanaceae',
  String? rotationFamille = 'solanaceae',
  Set<PrecedentCultural>? precedentsFavorables,
  Set<PrecedentCultural>? precedentsDefavorables,
}) =>
    FichePlante(
      id: id,
      nomScientifique: 'Solanum lycopersicum',
      familleBotanique: familleBotanique,
      categorie: CategoriePlante.legume,
      usages: {UsagePlante.alimentaire},
      nomsLocalises: const {'fr': 'Tomate'},
      besoins: BesoinsCulture(
          eau: BesoinEau.eleve, soleil: NiveauSoleil.pleinSoleil, phMin: 6, phMax: 7),
      espacementCm: 60,
      dureeAvantRecolteJoursMin: 70,
      dureeAvantRecolteJoursMax: 90,
      rotationFamille: rotationFamille,
      precedentsFavorables: precedentsFavorables,
      precedentsDefavorables: precedentsDefavorables,
    );

FamilleBotaniqueCache _familles(List<String> ids) => FamilleBotaniqueCache([
      for (final id in ids)
        FamilleBotanique(
          id: id,
          nomScientifique: id[0].toUpperCase() + id.substring(1),
          categories: {CategoriePlante.legume},
          nomsLocalises: {'fr': id},
        ),
    ]);

void main() {
  const verif = VerificateurIntegriteFamilles();

  test('no problem when every species family is covered and coherent', () {
    final problemes = verif.verifier([_espece()], _familles(['solanaceae']));
    expect(problemes, isEmpty);
  });

  test('flags a species whose family has no sheet', () {
    final problemes = verif.verifier([_espece()], _familles(['apiaceae']));
    expect(problemes, hasLength(1));
    expect(problemes.single.espece, 'LEG-001');
    expect(problemes.single.raison, contains('no family sheet'));
  });

  test('flags an incoherent rotation.famille vs famille_botanique', () {
    final espece = _espece(rotationFamille: 'solanacees');
    final problemes = verif.verifier([espece], _familles(['solanaceae']));
    expect(problemes, hasLength(1));
    expect(problemes.single.raison, contains('rotation.famille'));
  });

  test('a missing rotation.famille is not an incoherence (only coverage)', () {
    final espece = _espece(rotationFamille: null);
    expect(verif.verifier([espece], _familles(['solanaceae'])), isEmpty);
    expect(verif.verifier([espece], _familles(['apiaceae'])), hasLength(1));
  });

  group('cultural precedents (rotation avancée, Lot 2)', () {
    test('flags a family precedent with no family sheet', () {
      final espece = _espece(
        precedentsFavorables: {PrecedentCultural.famille('cucurbitaceae')},
      );
      final problemes = verif.verifier([espece], _familles(['solanaceae']));
      expect(problemes, hasLength(1));
      expect(problemes.single.raison,
          contains('favorable precedent "cucurbitaceae"'));
    });

    test('accepts a family precedent that resolves', () {
      final espece = _espece(
        precedentsDefavorables: {PrecedentCultural.famille('cucurbitaceae')},
      );
      final problemes =
          verif.verifier([espece], _familles(['solanaceae', 'cucurbitaceae']));
      expect(problemes, isEmpty);
    });

    test('group precedents are always valid (no family to resolve)', () {
      final espece = _espece(
        precedentsFavorables: {
          const PrecedentCultural.groupe(GroupeCultural.legumineuses),
          const PrecedentCultural.groupe(GroupeCultural.engraisVerts),
        },
      );
      expect(verif.verifier([espece], _familles(['solanaceae'])), isEmpty);
    });

    test('reports the offending direction (favorable vs défavorable)', () {
      final espece = _espece(
        precedentsDefavorables: {PrecedentCultural.famille('apiaceae')},
      );
      final problemes = verif.verifier([espece], _familles(['solanaceae']));
      expect(problemes.single.raison, contains('défavorable precedent'));
    });
  });
}
