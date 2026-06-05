import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_asset_source.dart';

/// In-memory [FicheAssetSource] for tests.
class _FakeSource implements FicheAssetSource {
  final Map<String, String> fiches;
  _FakeSource(this.fiches);

  @override
  Future<List<String>> listerCheminsFiches() async => fiches.keys.toList();

  @override
  Future<String> lireFiche(String chemin) async => fiches[chemin]!;
}

const _ficheInvalide = '''
id: cassee
categorie: legume
usages: [alimentaire]
# manque nom_scientifique, i18n, besoins, cycle...
''';

void main() {
  final golden =
      File('assets/fiches_plantes/legumes/tomate.yaml').readAsStringSync();

  test('loads valid sheets and skips a corrupt one (reported, not fatal)',
      () async {
    final erreurs = <String>[];
    final source = _FakeSource({
      'legumes/tomate.yaml': golden,
      'legumes/cassee.yaml': _ficheInvalide,
    });
    final loader = CatalogueLoader(
      source,
      (chemin, erreur) => erreurs.add(chemin),
    );

    final cache = await loader.charger();

    expect(cache.nombre, 1);
    expect(cache.parId('tomate'), isNotNull);
    expect(erreurs, ['legumes/cassee.yaml']);
  });

  test('an all-invalid catalogue yields an empty cache without throwing',
      () async {
    final source = _FakeSource({'a.yaml': _ficheInvalide, 'b.yaml': 'not: [a, map'});
    final cache = await CatalogueLoader(source).charger();
    expect(cache.nombre, 0);
  });
}
