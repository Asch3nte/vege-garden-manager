import 'package:flutter_test/flutter_test.dart';

import '../../tool/scrap_fiche.dart';

/// Routes requests to canned bodies by matching a substring of the URL.
class _FakeClient implements ClientHttp {
  final Map<String, String> reponses;
  _FakeClient(this.reponses);

  @override
  Future<String> obtenir(Uri url) async {
    for (final e in reponses.entries) {
      if (url.toString().contains(e.key)) return e.value;
    }
    throw Exception('no stub for $url');
  }
}

const _gbifOk = '''
{"canonicalName":"Solanum melongena","scientificName":"Solanum melongena L.",
 "family":"Solanaceae","genus":"Solanum","rank":"SPECIES"}''';

const _wikidataOk = '''
{"results":{"bindings":[{"family":{"type":"literal","value":"Solanaceae"}}]}}''';

const _wikidataAutreFamille = '''
{"results":{"bindings":[{"family":{"type":"literal","value":"Autrefamilyaceae"}}]}}''';

const _wikiFr = '{"title":"Aubergine","extract":"L\\u2019Aubergine est une plante."}';
const _wikiEn = '{"title":"Eggplant","extract":"Eggplant is a plant."}';

void main() {
  group('SourceGbif', () {
    test('parses taxonomy from the match endpoint', () async {
      final r = await SourceGbif(_FakeClient({'api.gbif.org': _gbifOk}))
          .interroger(terme: 'Solanum melongena');
      expect(r.nomScientifique, 'Solanum melongena');
      expect(r.familleBotanique, 'Solanaceae');
      expect(r.genre, 'Solanum');
    });
  });

  group('SourceWikidata', () {
    test('extracts the family from SPARQL bindings', () async {
      final r = await SourceWikidata(_FakeClient({'query.wikidata.org': _wikidataOk}))
          .interroger(terme: 'Solanum melongena');
      expect(r.familleBotanique, 'Solanaceae');
    });
  });

  group('SourceWikipedia', () {
    test('collects fr and en extracts when titles are given', () async {
      final r = await SourceWikipedia(_FakeClient({
        'fr.wikipedia.org': _wikiFr,
        'en.wikipedia.org': _wikiEn,
      })).interroger(terme: 'Aubergine', titreFr: 'Aubergine', titreEn: 'Eggplant');
      expect(r.descriptions['fr'], contains('Aubergine'));
      expect(r.descriptions['en'], contains('plant'));
    });
  });

  group('AgregateurBotanique', () {
    AgregateurBotanique agregateur(_FakeClient c) => AgregateurBotanique(
          gbif: SourceGbif(c),
          autres: [SourceWikidata(c), SourceWikipedia(c)],
        );

    test('merges sources into a draft and records attributions', () async {
      final brouillon = await agregateur(_FakeClient({
        'api.gbif.org': _gbifOk,
        'query.wikidata.org': _wikidataOk,
        'fr.wikipedia.org': _wikiFr,
        'en.wikipedia.org': _wikiEn,
      })).agreger(
        id: 'LEG-002',
        categorie: 'legume',
        nomCommunFr: 'Aubergine',
        terme: 'Solanum melongena',
        titreFr: 'Aubergine',
        titreEn: 'Eggplant',
      );

      final yaml = brouillon.versYaml();
      expect(brouillon.nomScientifique, 'Solanum melongena');
      expect(brouillon.familleBotanique, 'Solanaceae');
      expect(brouillon.avertissements, isEmpty);
      expect(yaml, contains('id: LEG-002'));
      expect(yaml, contains('famille_botanique: Solanaceae'));
      expect(yaml, contains('https://www.gbif.org'));
      expect(yaml, contains('TODO')); // agronomy left for human completion
    });

    test('flags a family mismatch across sources', () async {
      final brouillon = await agregateur(_FakeClient({
        'api.gbif.org': _gbifOk,
        'query.wikidata.org': _wikidataAutreFamille,
      })).agreger(
        id: 'LEG-002',
        categorie: 'legume',
        nomCommunFr: 'Aubergine',
        terme: 'Solanum melongena',
      );
      expect(
        brouillon.avertissements.any((a) => a.contains('familles divergentes')),
        isTrue,
      );
    });

    test('a failing secondary source is non-fatal and recorded', () async {
      // No stub for wikidata/wikipedia → they throw, GBIF still yields taxonomy.
      final brouillon = await agregateur(_FakeClient({'api.gbif.org': _gbifOk}))
          .agreger(
        id: 'LEG-002',
        categorie: 'legume',
        nomCommunFr: 'Aubergine',
        terme: 'Solanum melongena',
      );
      expect(brouillon.nomScientifique, 'Solanum melongena');
      expect(brouillon.avertissements, isNotEmpty);
    });
  });
}
