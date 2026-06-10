// Migration tool — legacy snake_case ids → canonical ADR-0005 ids.
//
// One-shot rename of the embedded catalogue (ADR-0005, Décision 2). Built and
// unit-tested in Lot 2; EXECUTED in Lot 3, once the missing mother sheets are
// authored (a variety whose mother is absent would otherwise be skipped at load
// time). Run with:  dart run bin/migrer_ids.dart
//
// The pure text transform [migrerContenu] preserves comments and formatting; it
// is covered by test/unit/infrastructure/catalogue/migrer_ids_test.dart.

import 'dart:io';

/// Legacy fiche id → canonical id, for the `id:` field, file rename and
/// `parent_id` derivation. A canonical id containing `-V` denotes a variety; its
/// `parent_id` is the part before `-V` (e.g. `LEG-001-V001` → `LEG-001`).
const Map<String, String> tableFiches = {
  'tomate': 'LEG-001',
  'tomate_coeur_de_boeuf': 'LEG-001-V001',
  'aubergine_violette_de_florence': 'LEG-002-V001',
  'betterave_chioggia': 'LEG-003-V001',
  'carotte': 'LEG-004',
  'carotte_nantaise_amelioree': 'LEG-004-V001',
  'celeri_rave_brilliant': 'LEG-005-V001',
  'chou_brocoli_calabrese': 'LEG-006-V001',
  'chou_cabus_rouge': 'LEG-007-V001',
  'chou_fleur_de_bretagne': 'LEG-008-V001',
  'concombre_marketmore': 'LEG-009-V001',
  'courge_butternut_ponca': 'LEG-010-V001',
  'courgette_black_beauty': 'LEG-011-V001',
  'epinard_geant_dhiver': 'LEG-012-V001',
  'haricot_vert_fin_de_bagnols': 'LEG-013-V001',
  'laitue': 'LEG-014',
  'laitue_batavia_rouge_grenobloise': 'LEG-014-V001',
  'navet_boule_dor': 'LEG-015-V001',
  'oignon_rouge_de_florence': 'LEG-016-V001',
  'poireau_bleu_de_solaise': 'LEG-017-V001',
  'pois_mangetout_carouby': 'LEG-018-V001',
  'poivron_corno_di_toro': 'LEG-019-V001',
  'pomme_de_terre_charlotte': 'LEG-020-V001',
  'potimarron_rouge_vif_etampes': 'LEG-021-V001',
  'radis_cherry_belle': 'LEG-022-V001',
  'artichaut_vert_de_laon': 'LEG-023-V001',
  'basilic': 'ARO-001',
};

/// Association reference (generic species name used in `beneficies`/
/// `defavorables`) → canonical **mother** id. Associations live at the species
/// level (ADR-0005), so refs resolve to mothers, not varieties.
///
/// Refs absent from this map are left untouched: they name plants with no fiche
/// yet (`capucine`, `fenouil`, `aneth`, `moutarde`, `soucis`, `persil`,
/// `fraise`, `ail`) or the ambiguous `courge` (LEG-010 squash vs LEG-021
/// potimarron) — to be resolved when those species get a fiche.
const Map<String, String> tableRefs = {
  'tomate': 'LEG-001',
  'betterave': 'LEG-003',
  'carotte': 'LEG-004',
  'celeri': 'LEG-005',
  'concombre': 'LEG-009',
  'haricot': 'LEG-013',
  'laitue': 'LEG-014',
  'oignon': 'LEG-016',
  'poireau': 'LEG-017',
  'pois': 'LEG-018',
  'poivron': 'LEG-019',
  'pomme_de_terre': 'LEG-020',
  'radis': 'LEG-022',
  'basilic': 'ARO-001',
};

final RegExp _ligneId = RegExp(r'^(id:\s*)(\S+)(.*)$');
final RegExp _ligneRefAssoc = RegExp(r'^(\s+- id:\s*)(\S+)(.*)$');

/// Rewrites a single sheet's text to the canonical id scheme.
///
/// - rewrites the top-level `id:` (preserving any trailing comment);
/// - inserts a `parent_id:` line for a variety (id containing `-V`);
/// - rewrites known association refs (`- id:`) to their mother id;
/// - leaves unknown refs and everything else untouched.
///
/// Returns the same text unchanged when the sheet's id is not in [tableFiches].
String migrerContenu(
  String contenu, {
  Map<String, String> fiches = tableFiches,
  Map<String, String> refs = tableRefs,
}) {
  final lignes = contenu.split('\n');
  final sortie = <String>[];

  for (final ligne in lignes) {
    final idMatch = _ligneId.firstMatch(ligne);
    if (idMatch != null) {
      final ancien = idMatch.group(2)!;
      final nouveau = fiches[ancien];
      if (nouveau == null) {
        sortie.add(ligne); // unknown sheet — leave as-is
        continue;
      }
      sortie.add('${idMatch.group(1)}$nouveau${idMatch.group(3)}');
      if (nouveau.contains('-V')) {
        sortie.add('parent_id: ${nouveau.substring(0, nouveau.indexOf('-V'))}');
      }
      continue;
    }

    final refMatch = _ligneRefAssoc.firstMatch(ligne);
    if (refMatch != null) {
      final nouveau = refs[refMatch.group(2)!];
      if (nouveau != null) {
        sortie.add('${refMatch.group(1)}$nouveau${refMatch.group(3)}');
        continue;
      }
    }
    sortie.add(ligne);
  }
  return sortie.join('\n');
}

/// New file name (`<canonical-id>.yaml`) for a sheet whose legacy id is the
/// basename of [cheminAncien], or `null` if the sheet is not in [tableFiches].
String? nouveauNomFichier(String cheminAncien) {
  final base = cheminAncien.split(Platform.pathSeparator).last;
  final ancienId = base.endsWith('.yaml')
      ? base.substring(0, base.length - '.yaml'.length)
      : base;
  final nouveau = tableFiches[ancienId];
  return nouveau == null ? null : '$nouveau.yaml';
}

Future<void> main() async {
  const racine = 'assets/fiches_plantes';
  final fichiers = Directory(racine)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.yaml') && !f.path.contains('/_schema/'));

  var migrees = 0;
  for (final fichier in fichiers) {
    final nouveauNom = nouveauNomFichier(fichier.path);
    if (nouveauNom == null) {
      stderr.writeln('SKIP (id inconnu) : ${fichier.path}');
      continue;
    }
    final contenu = await fichier.readAsString();
    final migre = migrerContenu(contenu);
    final dossier = fichier.parent.path;
    await File('$dossier${Platform.pathSeparator}$nouveauNom')
        .writeAsString(migre);
    if (fichier.uri.pathSegments.last != nouveauNom) await fichier.delete();
    migrees++;
    stdout.writeln('OK : ${fichier.path} → $nouveauNom');
  }
  stdout.writeln('$migrees fiche(s) migrée(s).');
}
