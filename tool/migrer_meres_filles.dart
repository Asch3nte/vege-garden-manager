// One-shot migration generator (ADR-0005, Lot 3): turns each legacy variety
// sheet into a canonical **mother** (species) sheet + a slim **variety** sheet,
// rewriting association refs to canonical mother ids and emitting clean YAML.
//
// Mother  = agronomy lifted from the source sheet + sourced taxonomy/description
//           (tool/scrap_fiche.dart) + association refs rewritten to mother ids.
// Variety = identity (names, variety description, cultivar scientific name) +
//           post-harvest blocks (conservation, culinary uses); everything else
//           is inherited from the mother.
//
// Run:  dart run tool/migrer_meres_filles.dart
// Output is verified by test/unit/infrastructure/catalogue/catalogue_reel_test.dart
// (the whole catalogue must parse, validate and map). Aubergine (LEG-002) was
// authored by hand and is intentionally not in the table.

import 'dart:io';
import 'package:yaml/yaml.dart';

const _dossier = 'assets/fiches_plantes';

/// Generic association ref (species name) → canonical mother id.
const Map<String, String> refs = {
  'tomate': 'LEG-001',
  'betterave': 'LEG-003',
  'carotte': 'LEG-004',
  'celeri': 'LEG-005',
  'concombre': 'LEG-009',
  'courge': 'LEG-010',
  'haricot': 'LEG-013',
  'laitue': 'LEG-014',
  'oignon': 'LEG-016',
  'poireau': 'LEG-017',
  'pois': 'LEG-018',
  'poivron': 'LEG-019',
  'pomme_de_terre': 'LEG-020',
  'radis': 'LEG-022',
  'basilic': 'ARO-001',
  // No fiche yet (left dangling): capucine, fenouil, aneth, moutarde, soucis,
  // persil, fraise, ail.
};

class Espece {
  final String mereId, dossier, ficheAgro, sci, famille, nomFr, nomEn;
  final List<String> altFr;
  final String descFr, descEn, wikiFr;
  final String? ficheVariete, varieteId;
  const Espece(this.mereId, this.dossier, this.ficheAgro, this.sci, this.famille,
      this.nomFr, this.nomEn, this.altFr, this.descFr, this.descEn, this.wikiFr,
      {this.ficheVariete, this.varieteId});
}

const especes = <Espece>[
  Espece('LEG-001', 'legumes', 'tomate', 'Solanum lycopersicum', 'Solanaceae',
      'Tomate', 'Tomato', ["Pomme d'amour"],
      "Plante annuelle de la famille des Solanacées, cultivée pour ses fruits charnus consommés comme légumes-fruits, crus ou cuits. Gourmande en chaleur, en soleil et en sol riche.",
      'Annual plant of the Solanaceae family, grown for its fleshy fruit eaten as a vegetable, raw or cooked.',
      'Tomate', ficheVariete: 'tomate_coeur_de_boeuf', varieteId: 'LEG-001-V001'),
  Espece('LEG-003', 'legumes', 'betterave_chioggia', 'Beta vulgaris', 'Amaranthaceae',
      'Betterave', 'Beetroot', ['Betterave potagère', 'Betterave rouge'],
      "Plante potagère bisannuelle de la famille des Amaranthacées, cultivée comme annuelle pour sa racine charnue consommée comme légume ; les jeunes feuilles sont aussi comestibles.",
      'Root vegetable (Beta vulgaris), eaten raw, roasted, steamed or boiled; the leaves are edible too.',
      'Betterave_potagère', ficheVariete: 'betterave_chioggia', varieteId: 'LEG-003-V001'),
  Espece('LEG-004', 'legumes', 'carotte', 'Daucus carota', 'Apiaceae',
      'Carotte', 'Carrot', ['Carotte cultivée'],
      "Légume-racine bisannuel de la famille des Apiacées, cultivé en annuel pour sa racine pivotante charnue, riche en carotène. Préfère les sols meubles, profonds et sans cailloux.",
      'Root vegetable of the Apiaceae family, typically orange and rich in beta-carotene; a biennial grown as an annual.',
      'Carotte', ficheVariete: 'carotte_nantaise_amelioree', varieteId: 'LEG-004-V001'),
  Espece('LEG-005', 'legumes', 'celeri_rave_brilliant', 'Apium graveolens', 'Apiaceae',
      'Céleri-rave', 'Celeriac', ['Céleri-rave'],
      "Variété de céleri de la famille des Apiacées, cultivée pour son hypocotyle renflé (boule) charnu et parfumé, consommé comme légume-racine.",
      'A group of Apium graveolens cultivars grown for their edible bulb-like hypocotyl.',
      'Céleri-rave', ficheVariete: 'celeri_rave_brilliant', varieteId: 'LEG-005-V001'),
  Espece('LEG-006', 'legumes', 'chou_brocoli_calabrese', 'Brassica oleracea', 'Brassicaceae',
      'Chou brocoli', 'Broccoli', ['Brocoli'],
      "Chou de la famille des Brassicacées (groupe Italica), cultivé pour ses inflorescences vertes denses consommées comme légume avant floraison.",
      'A Brassica oleracea cultivar (Italica group) grown for its edible green flower head.',
      'Brocoli', ficheVariete: 'chou_brocoli_calabrese', varieteId: 'LEG-006-V001'),
  Espece('LEG-007', 'legumes', 'chou_cabus_rouge', 'Brassica oleracea', 'Brassicaceae',
      'Chou cabus', 'Cabbage', ['Chou pommé'],
      "Chou pommé de la famille des Brassicacées, à tête dense de feuilles serrées et lisses, consommé comme légume-feuille.",
      'A leafy Brassica oleracea grown for its dense-leaved head.',
      'Chou_cabus', ficheVariete: 'chou_cabus_rouge', varieteId: 'LEG-007-V001'),
  Espece('LEG-008', 'legumes', 'chou_fleur_de_bretagne', 'Brassica oleracea', 'Brassicaceae',
      'Chou-fleur', 'Cauliflower', [],
      "Chou de la famille des Brassicacées cultivé pour son méristème floral hypertrophié et charnu (la pomme), consommé comme légume.",
      'A Brassica oleracea cultivar grown for its dense head of undeveloped flower buds (the curd).',
      'Chou-fleur', ficheVariete: 'chou_fleur_de_bretagne', varieteId: 'LEG-008-V001'),
  Espece('LEG-009', 'legumes', 'concombre_marketmore', 'Cucumis sativus', 'Cucurbitaceae',
      'Concombre', 'Cucumber', [],
      "Plante potagère grimpante de la famille des Cucurbitacées, cultivée pour son fruit allongé consommé comme légume, cru ou en condiment.",
      'A creeping vine of the Cucurbitaceae family grown for its cylindrical fruit used as a culinary vegetable.',
      'Concombre', ficheVariete: 'concombre_marketmore', varieteId: 'LEG-009-V001'),
  Espece('LEG-010', 'legumes', 'courge_butternut_ponca', 'Cucurbita moschata', 'Cucurbitaceae',
      'Courge musquée', 'Butternut squash', ['Butternut'],
      "Espèce de courge de la famille des Cucurbitacées, cultivée pour son fruit à chair musquée consommé à maturité ; tolère bien la chaleur humide.",
      'A Cucurbita moschata squash grown for its sweet, musky flesh; tolerant of hot, humid weather.',
      'Cucurbita_moschata', ficheVariete: 'courge_butternut_ponca', varieteId: 'LEG-010-V001'),
  Espece('LEG-011', 'legumes', 'courgette_black_beauty', 'Cucurbita pepo', 'Cucurbitaceae',
      'Courgette', 'Zucchini', [],
      "Courge d'été de la famille des Cucurbitacées, récoltée jeune quand le fruit est encore tendre, consommée comme légume.",
      'A summer squash (Cucurbita pepo) harvested young, while the fruit is still tender.',
      'Courgette', ficheVariete: 'courgette_black_beauty', varieteId: 'LEG-011-V001'),
  Espece('LEG-012', 'legumes', 'epinard_geant_dhiver', 'Spinacia oleracea', 'Amaranthaceae',
      'Épinard', 'Spinach', [],
      "Plante potagère annuelle de la famille des Amaranthacées, cultivée pour ses feuilles tendres consommées comme légume, crues ou cuites.",
      'A leafy green of the Amaranthaceae family eaten fresh or cooked.',
      'Épinard', ficheVariete: 'epinard_geant_dhiver', varieteId: 'LEG-012-V001'),
  Espece('LEG-013', 'legumes', 'haricot_vert_fin_de_bagnols', 'Phaseolus vulgaris', 'Fabaceae',
      'Haricot', 'Common bean', ['Haricot commun'],
      "Plante annuelle de la famille des Fabacées, cultivée pour ses gousses ou ses graines riches en protéines ; fixe l'azote de l'air.",
      'An annual legume (Fabaceae) grown for its pods or protein-rich seeds; it fixes atmospheric nitrogen.',
      'Haricot_commun', ficheVariete: 'haricot_vert_fin_de_bagnols', varieteId: 'LEG-013-V001'),
  Espece('LEG-014', 'legumes', 'laitue', 'Lactuca sativa', 'Asteraceae',
      'Laitue', 'Lettuce', ['Salade'],
      "Légume-feuille annuel de la famille des Astéracées, à cycle court, cultivé pour ses feuilles tendres consommées en salade. Apprécie la fraîcheur.",
      'A short-cycle annual leaf vegetable of the Asteraceae family, mostly eaten raw in salads.',
      'Laitue_cultivée', ficheVariete: 'laitue_batavia_rouge_grenobloise', varieteId: 'LEG-014-V001'),
  Espece('LEG-015', 'legumes', 'navet_boule_dor', 'Brassica rapa', 'Brassicaceae',
      'Navet', 'Turnip', [],
      "Plante potagère de la famille des Brassicacées, cultivée pour sa racine charnue arrondie ou allongée consommée comme légume.",
      'A root vegetable (Brassica rapa) grown for its fleshy taproot.',
      'Navet', ficheVariete: 'navet_boule_dor', varieteId: 'LEG-015-V001'),
  Espece('LEG-016', 'legumes', 'oignon_rouge_de_florence', 'Allium cepa', 'Amaryllidaceae',
      'Oignon', 'Onion', ['Ognon'],
      "Plante bisannuelle de la famille des Amaryllidacées, cultivée pour son bulbe à saveur et odeur fortes, consommé comme légume ou condiment.",
      'A bulb vegetable (Allium cepa), the most widely cultivated species of the genus Allium.',
      'Oignon', ficheVariete: 'oignon_rouge_de_florence', varieteId: 'LEG-016-V001'),
  Espece('LEG-017', 'legumes', 'poireau_bleu_de_solaise', 'Allium ampeloprasum', 'Amaryllidaceae',
      'Poireau', 'Leek', [],
      "Plante potagère de la famille des Amaryllidacées, cultivée pour ses feuilles engainantes (le « blanc ») consommées comme légume.",
      'A cultivar of Allium ampeloprasum grown for its edible bundle of leaf sheaths.',
      'Poireau', ficheVariete: 'poireau_bleu_de_solaise', varieteId: 'LEG-017-V001'),
  Espece('LEG-018', 'legumes', 'pois_mangetout_carouby', 'Pisum sativum', 'Fabaceae',
      'Pois', 'Pea', ['Petit pois', 'Pois cultivé'],
      "Plante annuelle de la famille des Fabacées, cultivée pour ses graines (petits pois) ou ses gousses ; fixe l'azote de l'air.",
      'An annual legume (Fabaceae) grown for its seeds or pods; it fixes atmospheric nitrogen.',
      'Pois_cultivé', ficheVariete: 'pois_mangetout_carouby', varieteId: 'LEG-018-V001'),
  Espece('LEG-019', 'legumes', 'poivron_corno_di_toro', 'Capsicum annuum', 'Solanaceae',
      'Poivron', 'Bell pepper', ['Piment doux'],
      "Variété de piment doux de la famille des Solanacées à gros fruits, cultivée pour ses fruits consommés comme légumes, crus ou cuits.",
      'Large, sweet-fruited cultivars of Capsicum annuum eaten as a vegetable, raw or cooked.',
      'Poivron', ficheVariete: 'poivron_corno_di_toro', varieteId: 'LEG-019-V001'),
  Espece('LEG-020', 'legumes', 'pomme_de_terre_charlotte', 'Solanum tuberosum', 'Solanaceae',
      'Pomme de terre', 'Potato', ['Patate'],
      "Plante de la famille des Solanacées cultivée pour ses tubercules comestibles riches en amidon ; vivace par ses tubercules mais cultivée en annuelle.",
      'Grown for its starchy edible tubers (Solanum tuberosum); a perennial cultivated as an annual.',
      'Pomme_de_terre', ficheVariete: 'pomme_de_terre_charlotte', varieteId: 'LEG-020-V001'),
  Espece('LEG-021', 'legumes', 'potimarron_rouge_vif_etampes', 'Cucurbita maxima', 'Cucurbitaceae',
      'Potimarron', 'Kuri squash', ['Potiron doux'],
      "Groupe de cultivars de courge (Cucurbita maxima) à chair dense et saveur de châtaigne, consommée comme légume à maturité.",
      'A Cucurbita maxima cultivar group with dense, chestnut-flavored flesh.',
      'Potimarron', ficheVariete: 'potimarron_rouge_vif_etampes', varieteId: 'LEG-021-V001'),
  Espece('LEG-022', 'legumes', 'radis_cherry_belle', 'Raphanus sativus', 'Brassicaceae',
      'Radis', 'Radish', [],
      "Plante potagère de la famille des Brassicacées, à cycle très court, cultivée pour son hypocotyle charnu consommé cru comme légume.",
      'A fast-growing Brassicaceae grown for its edible taproot, usually eaten raw.',
      'Radis', ficheVariete: 'radis_cherry_belle', varieteId: 'LEG-022-V001'),
  Espece('LEG-023', 'legumes', 'artichaut_vert_de_laon', 'Cynara cardunculus', 'Asteraceae',
      'Artichaut', 'Artichoke', ['Artichaut commun'],
      "Plante vivace de la famille des Astéracées cultivée pour ses capitules floraux (têtes) charnus, consommés comme légume avant floraison.",
      'A perennial thistle (Asteraceae) cultivated for its edible flower heads.',
      'Artichaut', ficheVariete: 'artichaut_vert_de_laon', varieteId: 'LEG-023-V001'),
  Espece('ARO-001', 'aromatiques', 'basilic', 'Ocimum basilicum', 'Lamiaceae',
      'Basilic', 'Basil', ['Basilic commun', 'Basilic doux'],
      "Plante aromatique annuelle de la famille des Lamiacées, originaire des régions tropicales, cultivée pour ses feuilles parfumées. En climat tempéré, elle se cultive en annuelle.",
      'A culinary herb of the Lamiaceae family, native to the tropics, grown for its fragrant leaves.',
      'Basilic_commun'),
];

// ── YAML emission ────────────────────────────────────────────────────────────

const _flowKeys = {'noms_alternatifs', 'precedents_favorables',
    'precedents_defavorables', 'fr', 'en'};
const _inlineKeys = {'raison_i18n', 'conditions_i18n'};

String _scalar(Object? v) {
  if (v is String) {
    if (v.contains("'")) {
      return '"${v.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
    }
    final besoinQuote = v.isEmpty ||
        v.trim() != v ||
        v.startsWith('- ') ||
        RegExp(r'''[:#\[\]{}",&*!|>%@`]''').hasMatch(v);
    return besoinQuote ? "'$v'" : v;
  }
  return '$v';
}

String _flowScalar(Object? v) {
  if (v is String && RegExp(r'[,\[\]{}:]').hasMatch(v)) {
    return v.contains("'") ? '"$v"' : "'$v'";
  }
  return '$v';
}

String _flowQuoted(Object? v) => v is String
    ? '"${v.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"'
    : '$v';

String _flowMap(Map m) =>
    '{ ${m.entries.map((e) => '${e.key}: ${_flowQuoted(e.value)}').join(', ')} }';

String _folded(String texte, int indent) {
  final pad = '  ' * indent;
  final mots = texte.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ');
  final lignes = <String>[];
  var cur = StringBuffer();
  for (final m in mots) {
    if (cur.isNotEmpty && cur.length + 1 + m.length > 74) {
      lignes.add(cur.toString());
      cur = StringBuffer();
    }
    if (cur.isNotEmpty) cur.write(' ');
    cur.write(m);
  }
  if (cur.isNotEmpty) lignes.add(cur.toString());
  final b = StringBuffer('>\n');
  for (final l in lignes) {
    b.writeln('$pad$l');
  }
  return b.toString();
}

String _dumpMap(Map m, int indent) {
  final pad = '  ' * indent;
  final b = StringBuffer();
  m.forEach((k, v) {
    final key = '$k';
    if (v is Map && _inlineKeys.contains(key)) {
      b.writeln('$pad$key: ${_flowMap(v)}');
    } else if (v is Map) {
      if (v.isEmpty) {
        b.writeln('$pad$key: {}');
      } else {
        b.writeln('$pad$key:');
        b.write(_dumpMap(v, indent + 1));
      }
    } else if (v is List) {
      b.write(_dumpListe(key, v, indent));
    } else {
      b.writeln('$pad$key: ${_scalar(v)}');
    }
  });
  return b.toString();
}

String _dumpListe(String key, List l, int indent) {
  final pad = '  ' * indent;
  if (l.isEmpty) return '$pad$key: []\n';
  if (l.every((e) => e is num)) return '$pad$key: [${l.join(', ')}]\n';
  if (_flowKeys.contains(key) && l.every((e) => e is! Map && e is! List)) {
    return '$pad$key: [${l.map(_flowScalar).join(', ')}]\n';
  }
  final b = StringBuffer('$pad$key:\n');
  for (final e in l) {
    if (e is Map) {
      b.write(_dumpItemMap(e, indent + 1));
    } else {
      b.writeln('$pad  - ${_scalar(e)}');
    }
  }
  return b.toString();
}

String _dumpItemMap(Map m, int indent) {
  final pad = '  ' * indent;
  final b = StringBuffer();
  var first = true;
  m.forEach((k, v) {
    final prefix = first ? '$pad- ' : '$pad  ';
    first = false;
    final key = '$k';
    if (v is Map && _inlineKeys.contains(key)) {
      b.writeln('$prefix$key: ${_flowMap(v)}');
    } else {
      b.writeln('$prefix$key: ${_scalar(v)}');
    }
  });
  return b.toString();
}

Map _reecrireRefs(Map assoc) {
  final out = {};
  for (final section in ['beneficies', 'defavorables']) {
    if (assoc[section] == null) continue;
    out[section] = [
      for (final item in (assoc[section] as List))
        {
          for (final e in (item as Map).entries)
            e.key: (e.key == 'id' && refs.containsKey(e.value))
                ? refs[e.value]
                : e.value,
        }
    ];
  }
  return out;
}

// ── Build ──────────────────────────────────────────────────────────────────

String construireMere(Espece e, Map agro) {
  final fr = (agro['i18n'] as Map)['fr'] as Map;
  final b = StringBuffer()
    ..writeln('# Fiche mère (espèce) — ${e.nomFr}.')
    ..writeln('# Taxonomie & description : tool/scrap_fiche.dart (GBIF × Wikidata × Wikipédia).')
    ..writeln('# Agronomie généralisée depuis la variété + références. Généré (Lot 3), relu.')
    ..writeln('id: ${e.mereId}')
    ..writeln('version_fiche: 1')
    ..writeln('categorie: ${agro['categorie']}');
  if (agro['sous_type'] != null) b.writeln('sous_type: ${agro['sous_type']}');
  b.writeln('schema_version: 1');
  if (agro['difficulte'] != null) b.writeln('difficulte: ${agro['difficulte']}');
  b.writeln('usages:');
  for (final u in (agro['usages'] as List)) {
    b.writeln('  - $u');
  }
  b.writeln('');
  if (agro['rusticite'] != null) {
    b
      ..writeln('rusticite:')
      ..write(_dumpMap(agro['rusticite'] as Map, 1));
  }
  b
    ..writeln('nom_scientifique: ${_scalar(e.sci)}')
    ..writeln('famille_botanique: ${e.famille}')
    ..writeln('')
    ..writeln('i18n:')
    ..writeln('  fr:')
    ..writeln('    nom_commun: ${_scalar(e.nomFr)}');
  if (e.altFr.isNotEmpty) {
    b.writeln('    noms_alternatifs: [${e.altFr.map(_flowScalar).join(', ')}]');
  }
  b.write('    description: ${_folded(e.descFr, 3)}');
  if (fr['conseils_culture'] != null) {
    b.write('    conseils_culture: ${_folded(fr['conseils_culture'] as String, 3)}');
  }
  if (fr['conseils_recolte'] != null) {
    b.write('    conseils_recolte: ${_folded(fr['conseils_recolte'] as String, 3)}');
  }
  if (fr['erreurs_frequentes'] != null) {
    b.writeln('    erreurs_frequentes:');
    for (final x in (fr['erreurs_frequentes'] as List)) {
      b.writeln('      - ${_scalar(x)}');
    }
  }
  b
    ..writeln('  en:')
    ..writeln('    nom_commun: ${_scalar(e.nomEn)}')
    ..write('    description: ${_folded(e.descEn, 3)}')
    ..writeln('')
    ..writeln('besoins:')
    ..write(_dumpMap(agro['besoins'] as Map, 1))
    ..writeln('cycle:')
    ..write(_dumpMap(agro['cycle'] as Map, 1));
  if (agro['periodes'] != null && (agro['periodes'] as Map).isNotEmpty) {
    b
      ..writeln('periodes:')
      ..write(_dumpMap(agro['periodes'] as Map, 1));
  }
  if (agro['associations'] != null) {
    b
      ..writeln('associations:')
      ..write(_dumpMap(_reecrireRefs(agro['associations'] as Map), 1));
  }
  if (agro['rotation'] != null) {
    b
      ..writeln('rotation:')
      ..write(_dumpMap(agro['rotation'] as Map, 1));
  }
  b
    ..writeln('')
    ..writeln('sources:')
    ..writeln('  - https://www.gbif.org  # taxonomie')
    ..writeln('  - https://www.wikidata.org  # vérification famille')
    ..writeln('  - https://fr.wikipedia.org/wiki/${e.wikiFr}  # description')
    ..writeln('contributeurs:')
    ..writeln('  - "@potagerer"');
  return b.toString();
}

String construireFille(Espece e, Map v) {
  final fr = (v['i18n'] as Map)['fr'] as Map;
  final en = (v['i18n'] as Map)['en'] as Map?;
  // When the mother is built from the variety's own sheet (single-variety
  // species), its conseils/erreurs are already on the mother → the variety
  // inherits them and must not repeat them. Only the genuinely variety-specific
  // names + description stay on the variety.
  final memeSource = e.ficheAgro == e.ficheVariete;
  final b = StringBuffer()
    ..writeln('# Fiche fille (variété) — ${fr['nom_commun']}. Hérite de ${e.mereId}.')
    ..writeln('# Ne déclare que ce qui diffère de la mère (héritage sparse, ADR-0005).')
    ..writeln('id: ${e.varieteId}')
    ..writeln('parent_id: ${e.mereId}')
    ..writeln('version_fiche: 1')
    ..writeln('schema_version: 1')
    ..writeln('')
    ..writeln('nom_scientifique: ${_scalar(v['nom_scientifique'])}')
    ..writeln('')
    ..writeln('i18n:')
    ..writeln('  fr:')
    ..writeln('    nom_commun: ${_scalar(fr['nom_commun'])}');
  if (fr['noms_alternatifs'] != null) {
    b.writeln('    noms_alternatifs: [${(fr['noms_alternatifs'] as List).map(_flowScalar).join(', ')}]');
  }
  b.write('    description: ${_folded(fr['description'] as String, 3)}');
  if (!memeSource && fr['conseils_culture'] != null) {
    b.write('    conseils_culture: ${_folded(fr['conseils_culture'] as String, 3)}');
  }
  if (!memeSource && fr['conseils_recolte'] != null) {
    b.write('    conseils_recolte: ${_folded(fr['conseils_recolte'] as String, 3)}');
  }
  if (!memeSource && fr['erreurs_frequentes'] != null) {
    b.writeln('    erreurs_frequentes:');
    for (final x in (fr['erreurs_frequentes'] as List)) {
      b.writeln('      - ${_scalar(x)}');
    }
  }
  if (en != null) {
    b.writeln('  en:');
    if (en['nom_commun'] != null) b.writeln('    nom_commun: ${_scalar(en['nom_commun'])}');
    if (en['description'] != null) {
      b.write('    description: ${_folded(en['description'] as String, 3)}');
    }
  }
  b.writeln('');
  if (v['conservation'] != null) {
    b.write(_dumpListe('conservation', v['conservation'] as List, 0));
  }
  if (v['utilisations_culinaires_i18n'] != null) {
    b
      ..writeln('utilisations_culinaires_i18n:')
      ..write(_dumpMap(v['utilisations_culinaires_i18n'] as Map, 1));
  }
  b.writeln('');
  if (v['sources'] != null) {
    b.writeln('sources:');
    for (final s in (v['sources'] as List)) {
      b.writeln('  - $s');
    }
  }
  b
    ..writeln('contributeurs:')
    ..writeln('  - "@potagerer"');
  return b.toString();
}

Future<void> main() async {
  for (final e in especes) {
    final agro = loadYaml(
        await File('$_dossier/${e.dossier}/${e.ficheAgro}.yaml').readAsString()) as Map;
    await File('$_dossier/${e.dossier}/${e.mereId}.yaml')
        .writeAsString(construireMere(e, agro));
    stdout.writeln('mère   ${e.mereId} (depuis ${e.ficheAgro})');

    if (e.ficheVariete != null) {
      final v = loadYaml(await File('$_dossier/${e.dossier}/${e.ficheVariete}.yaml')
          .readAsString()) as Map;
      await File('$_dossier/${e.dossier}/${e.varieteId}.yaml')
          .writeAsString(construireFille(e, v));
      stdout.writeln('  fille ${e.varieteId} (depuis ${e.ficheVariete})');
    }
  }
  stdout.writeln('Terminé.');
}
