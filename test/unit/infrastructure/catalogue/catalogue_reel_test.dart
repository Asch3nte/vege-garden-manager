import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
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
const _refsSansFiche = {
  // capucine→FLE-001, soucis→FLE-002, fenouil→LEG-024, ail→LEG-025,
  // aneth→ARO-007, moutarde→ENG-001 : fiches créées (lot « fleurs compagnes »),
  // refs repointées. Restent sans fiche dédiée :
  'persil', 'fraise',
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

  test('content-lot fiches load with their expected category', () async {
    final cache = await CatalogueLoader(FilesystemFicheAssetSource()).charger();
    // id → expected category. Guards the recent content lots: « fleurs
    // compagnes » (resolves the formerly-orphan refs capucine, soucis, fenouil,
    // ail, aneth, moutarde) and « potagères courantes ».
    const attendu = {
      'FLE-001': CategoriePlante.fleur, // Capucine
      'FLE-002': CategoriePlante.fleur, // Souci
      'LEG-024': CategoriePlante.legume, // Fenouil
      'LEG-025': CategoriePlante.legume, // Ail
      'ARO-007': CategoriePlante.aromatique, // Aneth
      'ENG-001': CategoriePlante.engraisVert, // Moutarde blanche
      // Lot « potagères courantes » :
      'LEG-026': CategoriePlante.legume, // Fève
      'LEG-027': CategoriePlante.legume, // Échalote
      'LEG-028': CategoriePlante.legume, // Mâche
      'LEG-029': CategoriePlante.legume, // Bette
      'LEG-030': CategoriePlante.legume, // Melon
      'LEG-031': CategoriePlante.legume, // Chou de Bruxelles
      'LEG-032': CategoriePlante.legume, // Chou frisé (kale)
    };
    attendu.forEach((id, categorie) {
      final f = cache.parId(id);
      expect(f, isNotNull, reason: 'missing companion fiche $id');
      expect(f!.categorie, categorie, reason: '$id should be $categorie');
    });
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
