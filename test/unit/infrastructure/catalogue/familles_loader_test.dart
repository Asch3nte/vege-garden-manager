import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/familles_loader.dart';

/// In-memory [FamilleAssetSource] for tests.
class _FakeSource implements FamilleAssetSource {
  final Map<String, String> familles;
  _FakeSource(this.familles);

  @override
  Future<List<String>> listerCheminsFamilles() async => familles.keys.toList();

  @override
  Future<String> lireFamille(String chemin) async => familles[chemin]!;
}

const _valide = '''
id: solanaceae
nom_scientifique: Solanaceae
schema_version: 1
categories: [legume, fleur]
i18n:
  fr:
    nom_commun: Solanacées
    description: Tomate, aubergine, poivron, pomme de terre.
maladies_communes: [mildiou]
ravageurs_communs: [doryphore]
delai_retour_annees: 4
''';

/// id does not match the normalized scientific name.
const _idIncoherent = '''
id: solanacees
nom_scientifique: Solanaceae
schema_version: 1
categories: [legume]
i18n:
  fr:
    nom_commun: Solanacées
    description: x
''';

/// Unknown category token.
const _categorieInconnue = '''
id: solanaceae
nom_scientifique: Solanaceae
schema_version: 1
categories: [legumes]
i18n:
  fr:
    nom_commun: Solanacées
    description: x
''';

/// Missing French name.
const _sansNom = '''
id: apiaceae
nom_scientifique: Apiaceae
schema_version: 1
categories: [legume]
i18n:
  fr:
    description: x
''';

void main() {
  test('loads a valid family and maps every field', () async {
    final cache =
        await FamillesLoader(_FakeSource({'solanaceae.yaml': _valide})).charger();

    expect(cache.nombre, 1);
    final f = cache.parId('solanaceae')!;
    expect(f.nomScientifique, 'Solanaceae');
    expect(f.categories, {CategoriePlante.legume, CategoriePlante.fleur});
    expect(f.nomLocalise('fr'), 'Solanacées');
    expect(f.descriptionLocalisee('fr'), startsWith('Tomate'));
    expect(f.maladiesCommunes, {'mildiou'});
    expect(f.ravageursCommuns, {'doryphore'});
    expect(f.delaiRetourAnnees, 4);
  });

  test('skips invalid families (reported, not fatal)', () async {
    final erreurs = <String>[];
    final cache = await FamillesLoader(
      _FakeSource({
        'ok.yaml': _valide,
        'id.yaml': _idIncoherent,
        'cat.yaml': _categorieInconnue,
        'nom.yaml': _sansNom,
        'syntaxe.yaml': 'not: [a, map',
      }),
      (chemin, _) => erreurs.add(chemin),
    ).charger();

    expect(cache.nombre, 1);
    expect(cache.parId('solanaceae'), isNotNull);
    expect(
      erreurs..sort(),
      ['cat.yaml', 'id.yaml', 'nom.yaml', 'syntaxe.yaml'],
    );
  });

  test('an all-invalid set yields an empty cache without throwing', () async {
    final cache = await FamillesLoader(
      _FakeSource({'a.yaml': _sansNom, 'b.yaml': 'not: [a, map'}),
    ).charger();
    expect(cache.nombre, 0);
  });

  test('parCategorie returns only relevant families', () async {
    final cache =
        await FamillesLoader(_FakeSource({'s.yaml': _valide})).charger();
    expect(cache.parCategorie(CategoriePlante.fleur).map((f) => f.id),
        ['solanaceae']);
    expect(cache.parCategorie(CategoriePlante.aromatique), isEmpty);
  });
}
