import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/filesystem_fiche_asset_source.dart';

/// Guards the real embedded catalogue: every shipped sheet must parse, validate
/// and map cleanly, and every association ref must resolve. Runs against
/// `assets/fiches_plantes` via the filesystem source (no Flutter bundle needed).

/// Species referenced by associations that have no fiche yet (to be authored in
/// a later content lot). An association ref outside this set must resolve to a
/// real fiche id — otherwise it is a dead reference (a typo or a missed
/// migration), and this test fails.
const _refsSansFiche = {
  'capucine', 'fenouil', 'aneth', 'moutarde', 'soucis', 'persil', 'fraise',
  'ail',
};

void main() {
  test('the embedded catalogue loads with zero errors', () async {
    final source = FilesystemFicheAssetSource();
    final chemins = await source.listerCheminsFiches();
    expect(chemins, isNotEmpty, reason: 'expected sheets under assets/');

    final erreurs = <String>[];
    final cache = await CatalogueLoader(
      source,
      (chemin, erreur) => erreurs.add('$chemin: $erreur'),
    ).charger();

    expect(erreurs, isEmpty, reason: erreurs.join('\n'));
    expect(cache.nombre, chemins.length);
  });

  test('every association ref resolves to a fiche (or a known absent species)',
      () async {
    final cache = await CatalogueLoader(FilesystemFicheAssetSource()).charger();
    final ids = {for (final f in cache.toutes()) f.id};

    final mortes = <String>{};
    for (final f in cache.toutes()) {
      for (final ref in {...f.associationsBenefiques, ...f.associationsNegatives}) {
        if (!ids.contains(ref) && !_refsSansFiche.contains(ref)) {
          mortes.add('${f.id} → $ref');
        }
      }
    }
    expect(mortes, isEmpty, reason: 'dead association refs: $mortes');
  });
}
