// Reusable research/scrape tool — drafts a plant **species** sheet by cross-
// referencing several open-source botanical databases.
//
// Goal (ADR-0005, Lot 3): bootstrap a *mother* sheet (species level) so the
// catalogue is easy to grow. The tool reliably auto-fills **taxonomy** (cross-
// checked GBIF × Wikidata) and **descriptions** (Wikipedia fr/en). Agronomic
// fields have no clean open API, so they are emitted as TODO placeholders for
// human completion (generalised from existing variety sheets + horticultural
// references). Every contributing source is recorded in `sources:`.
//
// Usage:
//   dart run tool/scrap_fiche.dart "Solanum melongena" \
//       --cat LEG --num 002 --nom "Aubergine" --wiki-fr Aubergine --wiki-en Eggplant
//
// The open-data sources live in `tool/sources_botaniques.dart` (shared with
// `tool/scrap_famille.dart`) and are re-exported here for backward-compatible
// imports. Pure parsing/merge logic is covered by test/tool/scrap_fiche_test.dart
// via a fake [ClientHttp]; only the CLI `main` performs real network calls.

import 'dart:io';

import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';

import 'sources_botaniques.dart';

export 'sources_botaniques.dart';

/// A draft mother sheet built from the merged sources, plus any cross-check
/// warnings (e.g. family mismatch between GBIF and Wikidata).
class FicheBrouillon {
  final String id;
  final String categorie;
  final String nomCommunFr;
  final String? nomScientifique;
  final String? familleBotanique;
  final String? genre;
  final Map<String, String> descriptions;
  final List<String> sources;
  final List<String> avertissements;

  const FicheBrouillon({
    required this.id,
    required this.categorie,
    required this.nomCommunFr,
    this.nomScientifique,
    this.familleBotanique,
    this.genre,
    this.descriptions = const {},
    this.sources = const [],
    this.avertissements = const [],
  });

  /// Renders the draft as schema-compliant YAML. Taxonomy and descriptions are
  /// filled; agronomic blocks are TODO placeholders for human completion.
  String versYaml() {
    String bloc(String? v) => v ?? 'TODO';
    // Normalized family key (ADR-0006): links the species to its family sheet.
    final familleCle = familleBotanique == null
        ? 'TODO'
        : FamilleBotanique.normaliserCle(familleBotanique!);
    final descFr = descriptions['fr'];
    final descEn = descriptions['en'];
    final b = StringBuffer()
      ..writeln('# Fiche mère générée par tool/scrap_fiche.dart — À COMPLÉTER.')
      ..writeln('# Taxonomie/description sourcées ; agronomie à renseigner '
          '(généraliser depuis la variété + références).');
    if (familleBotanique != null) {
      b.writeln('# ℹ️ Vérifier qu\'une fiche famille "$familleCle" existe dans '
          '_familles/ (sinon la créer — ADR-0006).');
    }
    for (final a in avertissements) {
      b.writeln('# ⚠️ $a');
    }
    b
      ..writeln('id: $id')
      ..writeln('version_fiche: 1')
      ..writeln('categorie: $categorie')
      ..writeln('schema_version: 1')
      ..writeln('usages: [alimentaire] # TODO vérifier')
      ..writeln('')
      ..writeln('nom_scientifique: ${bloc(nomScientifique)}')
      ..writeln('famille_botanique: ${bloc(familleBotanique)}')
      ..writeln('')
      ..writeln('i18n:')
      ..writeln('  fr:')
      ..writeln('    nom_commun: $nomCommunFr')
      ..writeln('    description: >')
      ..writeln('      ${descFr ?? 'TODO'}');
    if (descEn != null) {
      b
        ..writeln('  en:')
        ..writeln('    description: >')
        ..writeln('      $descEn');
    }
    b
      ..writeln('')
      ..writeln('besoins: # TODO généraliser depuis la variété')
      ..writeln('  ensoleillement: TODO')
      ..writeln('  arrosage: TODO')
      ..writeln('  qualites_sol: [TODO]')
      ..writeln('  ph_min: 0.0 # TODO')
      ..writeln('  ph_max: 0.0 # TODO')
      ..writeln('cycle: # TODO')
      ..writeln('  type: TODO')
      ..writeln('  duree_avant_recolte_jours: [0, 0] # TODO')
      ..writeln('  espacement_cm: 0 # TODO')
      ..writeln('periodes: {} # TODO')
      ..writeln('rotation: # TODO compléter le délai de retour')
      ..writeln('  famille: $familleCle # clé famille normalisée (ADR-0006)')
      ..writeln('  delai_retour_annees: 0 # TODO')
      ..writeln('')
      ..writeln('sources:');
    for (final s in sources) {
      b.writeln('  - $s');
    }
    return b.toString();
  }
}

/// Orchestrates the sources: GBIF resolves the scientific name first, then the
/// other sources are queried with it; family is cross-checked across sources.
class AgregateurBotanique {
  final SourceGbif gbif;
  final List<SourceBotanique> autres;

  const AgregateurBotanique({required this.gbif, this.autres = const []});

  Future<FicheBrouillon> agreger({
    required String id,
    required String categorie,
    required String nomCommunFr,
    required String terme,
    String? titreFr,
    String? titreEn,
  }) async {
    final resultats = <ResultatSource>[];
    final sourcesUrls = <String>[];
    final avertissements = <String>[];

    final r0 =
        await gbif.interroger(terme: terme, titreFr: titreFr, titreEn: titreEn);
    resultats.add(r0);
    sourcesUrls.add(gbif.url);
    final sci = r0.nomScientifique;

    for (final s in autres) {
      try {
        resultats.add(await s.interroger(
            terme: terme,
            nomScientifique: sci,
            titreFr: titreFr,
            titreEn: titreEn));
        sourcesUrls.add(s.url);
      } on Exception catch (e) {
        avertissements.add('source ${s.nom} indisponible: $e');
      }
    }

    // Cross-check family across sources that report one.
    final familles = {
      for (final r in resultats)
        if (r.familleBotanique != null) r.source: r.familleBotanique!
    };
    if (familles.values.toSet().length > 1) {
      avertissements.add('familles divergentes entre sources: $familles');
    }

    final descriptions = <String, String>{};
    for (final r in resultats) {
      descriptions.addAll(r.descriptions);
    }

    return FicheBrouillon(
      id: id,
      categorie: categorie,
      nomCommunFr: nomCommunFr,
      nomScientifique: sci,
      familleBotanique: familles.values.isEmpty ? null : familles.values.first,
      genre: r0.genre,
      descriptions: descriptions,
      sources: sourcesUrls,
      avertissements: avertissements,
    );
  }
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/scrap_fiche.dart "<nom scientifique>" '
        '--cat LEG --num 002 --nom "Aubergine" --wiki-fr Aubergine --wiki-en Eggplant');
    exitCode = 64;
    return;
  }
  final terme = args.first;
  String? opt(String cle) {
    final i = args.indexOf('--$cle');
    return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
  }

  final cat = opt('cat') ?? 'LEG';
  final num = opt('num') ?? '000';
  final nom = opt('nom') ?? terme;

  final client = ClientHttpReseau();
  final agregateur = AgregateurBotanique(
    gbif: SourceGbif(client),
    autres: [SourceWikidata(client), SourceWikipedia(client)],
  );
  final brouillon = await agregateur.agreger(
    id: '$cat-$num',
    categorie: _categorieDepuisCode(cat),
    nomCommunFr: nom,
    terme: terme,
    titreFr: opt('wiki-fr'),
    titreEn: opt('wiki-en'),
  );
  stdout.write(brouillon.versYaml());
}

String _categorieDepuisCode(String code) => const {
      'LEG': 'legume',
      'ARO': 'aromatique',
      'FRU': 'fruit',
      'PFR': 'petit_fruit',
      'FLE': 'fleur',
      'CER': 'cereale',
      'ENG': 'engrais_vert',
    }[code] ??
    'legume';
