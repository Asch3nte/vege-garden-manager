import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseurs_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/filesystem_fiche_asset_source.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/verificateur_integrite_repulsifs.dart';

/// Guards the real embedded catalogue: every shipped sheet must parse, validate
/// and map cleanly, and every association ref must resolve. Runs against
/// `assets/fiches_plantes` via the filesystem source (no Flutter bundle needed).

/// Species referenced by associations that have no fiche yet (to be authored in
/// a later content lot). An association ref outside this set must resolve to a
/// real fiche id — otherwise it is a dead reference (a typo or a missed
/// migration), and this test fails.
///
/// Now empty: every association ref resolves to a real fiche id. When a future
/// content lot cites a not-yet-authored species, add its bare name here.
const _refsSansFiche = <String>{};

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
      for (final ref in [
        ...f.associationsBenefiques.map((a) => a.cibleId),
        ...f.associationsNegatives.map((a) => a.cibleId),
      ]) {
        if (!ids.contains(ref) && !_refsSansFiche.contains(ref)) {
          mortes.add('${f.id} → $ref');
        }
      }
    }
    expect(mortes, isEmpty, reason: 'dead association refs: $mortes');
  });

  test('the seeded species carry detailed watering (sensitive stages)',
      () async {
    final cache = await CatalogueLoader(FilesystemFicheAssetSource()).charger();
    // Species seeded in Lot 2 with real, documented sensitive stages + notes.
    const seedees = {'LEG-001', 'LEG-014', 'LEG-004', 'LEG-011', 'LEG-013',
        'ARO-001'};
    for (final id in seedees) {
      final f = cache.parId(id);
      expect(f, isNotNull, reason: 'missing seeded fiche $id');
      final detail = f!.besoins.arrosageDetaille;
      expect(detail, isNotNull, reason: '$id should carry arrosage_detaille');
      expect(detail!.aPhasesSensibles, isTrue,
          reason: '$id should list sensitive growth stages');
    }
  });

  test('every repulsif_contre / piege_a slug resolves to a bioaggressor',
      () async {
    final cache = await CatalogueLoader(FilesystemFicheAssetSource()).charger();
    final reference =
        await BioagresseursLoader(FilesystemBioagresseurAssetSource()).charger();

    final problemes = const VerificateurIntegriteRepulsifs()
        .verifier(cache.toutes(), reference);

    expect(problemes, isEmpty, reason: problemes.join('\n'));
  });
}
