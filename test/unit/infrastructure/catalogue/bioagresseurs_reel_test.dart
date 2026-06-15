import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseurs_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/familles_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/verificateur_integrite_bioagresseurs.dart';

/// Guards the real embedded bioaggressor reference (ADR-0006, Lot 4): it must
/// parse/validate/map cleanly, and every disease/pest slug listed by a family
/// sheet must resolve to a coherent reference entry. Runs against
/// `assets/fiches_plantes/_referentiels/bioagresseurs.yaml` via the filesystem
/// source (no Flutter bundle needed).
void main() {
  test('the embedded bioaggressor reference loads with zero errors', () async {
    final erreurs = <String>[];
    final cache = await BioagresseursLoader(
      FilesystemBioagresseurAssetSource(),
      (source, erreur) => erreurs.add('$source: $erreur'),
    ).charger();

    expect(erreurs, isEmpty, reason: erreurs.join('\n'));
    expect(cache.nombre, greaterThan(0));
  });

  test('every family disease/pest slug resolves to a coherent reference entry',
      () async {
    final familles = await FamillesLoader(FilesystemFamilleAssetSource()).charger();
    final reference =
        await BioagresseursLoader(FilesystemBioagresseurAssetSource()).charger();

    final problemes = const VerificateurIntegriteBioagresseurs()
        .verifier(familles.toutes(), reference);

    expect(problemes, isEmpty, reason: problemes.join('\n'));
  });
}
