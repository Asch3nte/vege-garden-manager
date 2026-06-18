// Reusable open-data botanical sources, shared by the research/scrape tools
// (tool/scrap_fiche.dart for species, tool/scrap_famille.dart for families).
//
// Pure Dart (no Flutter): these run under `dart run`, so nothing here may
// import `package:flutter`. Only the real [ClientHttpReseau] performs network
// calls; everything else is testable with a fake [ClientHttp].
//
// Licence note (repo is MIT, embeds data): Wikidata data is **CC0** (embeddable,
// incl. EPPO codes); GBIF backbone is CC-BY (taxonomy). Wikipedia summaries are
// **CC-BY-SA** → use as *research input* only, rewrite prose in the project's
// own voice before shipping. Every queried source is recorded in `sources:`.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
    this.userAgent =
        'PotAGerer/0.1 (https://github.com/Asch3nte; xcreten@gmail.com)',
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

/// Wikipedia REST summaries (fr + en) — short descriptions (research input).
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
