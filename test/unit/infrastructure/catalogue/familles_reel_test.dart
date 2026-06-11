import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/familles_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/filesystem_fiche_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/verificateur_integrite_familles.dart';

/// Guards the real embedded family reference (ADR-0006): every shipped family
/// sheet must parse, validate and map cleanly, and every species must point to
/// an existing, coherent family. Runs against `assets/fiches_plantes/_familles`
/// via the filesystem source (no Flutter bundle needed).
void main() {
  test('the embedded families load with zero errors', () async {
    final source = FilesystemFamilleAssetSource();
    final chemins = await source.listerCheminsFamilles();
    expect(chemins, isNotEmpty, reason: 'expected family sheets under _familles/');

    final erreurs = <String>[];
    final cache = await FamillesLoader(
      source,
      (chemin, erreur) => erreurs.add('$chemin: $erreur'),
    ).charger();

    expect(erreurs, isEmpty, reason: erreurs.join('\n'));
    expect(cache.nombre, chemins.length);
  });

  test('the family source does not pick up the registry index', () async {
    final chemins = await FilesystemFamilleAssetSource().listerCheminsFamilles();
    expect(chemins.any((p) => p.endsWith('familles_registry.yaml')), isFalse);
  });

  test('every species points to an existing, coherent family', () async {
    final familles = await FamillesLoader(FilesystemFamilleAssetSource()).charger();
    final especes =
        await CatalogueLoader(FilesystemFicheAssetSource()).charger();

    final problemes = const VerificateurIntegriteFamilles()
        .verifier(especes.toutes(), familles);

    expect(problemes, isEmpty, reason: problemes.join('\n'));
  });
}
