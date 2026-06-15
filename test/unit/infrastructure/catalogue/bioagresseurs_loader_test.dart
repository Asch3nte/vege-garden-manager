import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/type_bioagresseur.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseurs_loader.dart';

/// In-memory [BioagresseurAssetSource] returning a fixed YAML document.
class _FakeSource implements BioagresseurAssetSource {
  final String contenu;
  const _FakeSource(this.contenu);
  @override
  Future<String> lireReferentiel() async => contenu;
}

void main() {
  test('loads valid entries into the cache', () async {
    final cache = await BioagresseursLoader(const _FakeSource('''
schema_version: 1
bioagresseurs:
  mildiou:
    type: maladie
    i18n:
      fr: { nom: Mildiou }
  puceron:
    type: ravageur
    code_eppo: APHISP
    i18n:
      fr: { nom: Puceron }
''')).charger();

    expect(cache.nombre, 2);
    expect(cache.parId('mildiou')?.type, TypeBioagresseur.maladie);
    expect(cache.parId('puceron')?.codeEppo, 'APHISP');
    expect(cache.parType(TypeBioagresseur.ravageur), hasLength(1));
  });

  test('skips and reports an invalid entry, keeps valid ones', () async {
    final erreurs = <String>[];
    final cache = await BioagresseursLoader(const _FakeSource('''
bioagresseurs:
  mildiou:
    type: maladie
    i18n:
      fr: { nom: Mildiou }
  casse:
    type: champignon
    i18n:
      fr: { nom: Cassé }
'''), (s, e) => erreurs.add('$s: $e')).charger();

    expect(cache.nombre, 1);
    expect(cache.parId('mildiou'), isNotNull);
    expect(cache.parId('casse'), isNull);
    expect(erreurs, hasLength(1));
  });

  test('returns an empty cache and reports when the root is malformed',
      () async {
    final erreurs = <String>[];
    final cache = await BioagresseursLoader(
            const _FakeSource('- not a mapping'), (s, e) => erreurs.add('$e'))
        .charger();
    expect(cache.nombre, 0);
    expect(erreurs, hasLength(1));
  });

  test('returns an empty cache when the "bioagresseurs" key is missing',
      () async {
    final erreurs = <String>[];
    final cache = await BioagresseursLoader(
            const _FakeSource('schema_version: 1'), (s, e) => erreurs.add('$e'))
        .charger();
    expect(cache.nombre, 0);
    expect(erreurs, hasLength(1));
  });
}
