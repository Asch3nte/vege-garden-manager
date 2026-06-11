// Reusable research/scrape tool — drafts a plant sheet by cross-referencing
// several open-source botanical databases.
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
// Extensible by design: implement another [SourceBotanique] (PFAF dump,
// Permapeople API…) and add it to the [AgregateurBotanique] source list.
//
// Pure parsing/merge logic is covered by test/tool/scrap_fiche_test.dart via a
// fake [ClientHttp]; only the CLI `main` performs real network calls.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';

/// Minimal HTTP abstraction so sources can be unit-tested without the network.
abstract class ClientHttp {
  /// GETs [url] and returns the response body, or throws on a non-2xx status.
  Future<String> obtenir(Uri url);
}

/// Real [ClientHttp] over `package:http`, with a courteous User-Agent.
class ClientHttpReseau implements ClientHttp {
  final http.Client _client;
  final String userAgent;

  ClientHttpReseau({
    http.Client? client,
    this.userAgent = 'PotAGerer/0.1 (https://github.com/Asch3nte; xcreten@gmail.com)',
  }) : _client = client ?? http.Client();

  @override
  Future<String> obtenir(Uri url) async {
    final reponse = await _client.get(url, headers: {'User-Agent': userAgent});
    if (reponse.statusCode < 200 || reponse.statusCode >= 300) {
      throw HttpException('HTTP ${reponse.statusCode} for $url');
    }
    return reponse.body;
  }
}

/// Partial botanical data gathered from a single source.
class ResultatSource {
  final String source;
  final String? nomScientifique;
  final String? familleBotanique;
  final String? genre;

  /// Locale → description text (e.g. `{'fr': '…', 'en': '…'}`).
  final Map<String, String> descriptions;

  const ResultatSource({
    required this.source,
    this.nomScientifique,
    this.familleBotanique,
    this.genre,
    this.descriptions = const {},
  });
}

/// A queryable open-source botanical database.
abstract class SourceBotanique {
  String get nom;

  /// URL of the source, recorded in the draft's `sources:` for attribution.
  String get url;

  /// Queries the source. [nomScientifique], when already resolved (e.g. by
  /// GBIF), lets taxonomy sources answer precisely; [titreFr]/[titreEn] target
  /// encyclopaedic pages.
  Future<ResultatSource> interroger({
    required String terme,
    String? nomScientifique,
    String? titreFr,
    String? titreEn,
  });
}

/// GBIF taxonomic backbone — authoritative scientific name, family and genus.
class SourceGbif implements SourceBotanique {
  final ClientHttp _http;
  const SourceGbif(this._http);

  @override
  String get nom => 'GBIF';
  @override
  String get url => 'https://www.gbif.org';

  @override
  Future<ResultatSource> interroger({
    required String terme,
    String? nomScientifique,
    String? titreFr,
    String? titreEn,
  }) async {
    final url = Uri.https('api.gbif.org', '/v1/species/match',
        {'name': nomScientifique ?? terme});
    final json = jsonDecode(await _http.obtenir(url)) as Map<String, dynamic>;
    return ResultatSource(
      source: nom,
      nomScientifique: json['canonicalName'] as String? ??
          json['scientificName'] as String?,
      familleBotanique: json['family'] as String?,
      genre: json['genus'] as String?,
    );
  }
}

/// Wikidata (SPARQL) — independent family lookup by scientific name, used to
/// cross-check GBIF.
class SourceWikidata implements SourceBotanique {
  final ClientHttp _http;
  const SourceWikidata(this._http);

  @override
  String get nom => 'Wikidata';
  @override
  String get url => 'https://www.wikidata.org';

  @override
  Future<ResultatSource> interroger({
    required String terme,
    String? nomScientifique,
    String? titreFr,
    String? titreEn,
  }) async {
    final sci = nomScientifique ?? terme;
    final requete = '''
SELECT ?family WHERE {
  ?taxon wdt:P225 "$sci".
  OPTIONAL { ?taxon wdt:P171* ?f. ?f wdt:P105 wd:Q35409; wdt:P225 ?family. }
} LIMIT 1''';
    final url = Uri.https('query.wikidata.org', '/sparql',
        {'format': 'json', 'query': requete});
    final json = jsonDecode(await _http.obtenir(url)) as Map<String, dynamic>;
    final bindings = ((json['results'] as Map)['bindings'] as List);
    final famille = bindings.isEmpty
        ? null
        : ((bindings.first as Map)['family'] as Map?)?['value'] as String?;
    return ResultatSource(
        source: nom, nomScientifique: sci, familleBotanique: famille);
  }
}

/// Wikipedia REST summaries (fr + en) — short descriptions.
class SourceWikipedia implements SourceBotanique {
  final ClientHttp _http;
  const SourceWikipedia(this._http);

  @override
  String get nom => 'Wikipédia';
  @override
  String get url => 'https://fr.wikipedia.org';

  @override
  Future<ResultatSource> interroger({
    required String terme,
    String? nomScientifique,
    String? titreFr,
    String? titreEn,
  }) async {
    final descriptions = <String, String>{};
    for (final entry in {'fr': titreFr, 'en': titreEn}.entries) {
      final titre = entry.value;
      if (titre == null) continue;
      try {
        final url = Uri.https('${entry.key}.wikipedia.org',
            '/api/rest_v1/page/summary/${Uri.encodeComponent(titre)}');
        final json =
            jsonDecode(await _http.obtenir(url)) as Map<String, dynamic>;
        final extrait = json['extract'] as String?;
        if (extrait != null && extrait.isNotEmpty) {
          descriptions[entry.key] = extrait;
        }
      } on Exception {
        // A missing page is not fatal: skip that locale.
      }
    }
    return ResultatSource(source: nom, descriptions: descriptions);
  }
}

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

    final r0 = await gbif.interroger(terme: terme, titreFr: titreFr, titreEn: titreEn);
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
