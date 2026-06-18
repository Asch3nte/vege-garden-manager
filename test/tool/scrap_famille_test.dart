import 'package:flutter_test/flutter_test.dart';

import '../../tool/scrap_famille.dart';
import '../../tool/sources_botaniques.dart';

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

const _gbifFamille =
    '{"canonicalName":"Solanaceae","family":"Solanaceae","rank":"FAMILY"}';
const _gbifAutre =
    '{"canonicalName":"Autreaceae","family":"Autreaceae","rank":"FAMILY"}';
const _wikidataOk =
    '{"results":{"bindings":[{"family":{"type":"literal","value":"Solanaceae"}}]}}';
const _wikiFr =
    '{"title":"Solanaceae","extract":"Les Solanacées sont une famille."}';

void main() {
  AgregateurFamille agregateur(_FakeClient c) => AgregateurFamille(
        gbif: SourceGbif(c),
        autres: [SourceWikidata(c), SourceWikipedia(c)],
      );

  test('drafts a family sheet, normalizing the id and recording sources',
      () async {
    final brouillon = await agregateur(_FakeClient({
      'api.gbif.org': _gbifFamille,
      'query.wikidata.org': _wikidataOk,
      'fr.wikipedia.org': _wikiFr,
    })).agreger(
      nomScientifique: 'Solanaceae',
      nomCommunFr: 'Solanacées',
      categories: ['legume', 'fleur'],
      titreFr: 'Solanaceae',
    );

    final yaml = brouillon.versYaml();
    expect(brouillon.id, 'solanaceae');
    expect(brouillon.avertissements, isEmpty);
    expect(yaml, contains('id: solanaceae'));
    expect(yaml, contains('categories: [legume, fleur]'));
    expect(yaml, contains('Les Solanacées'));
    expect(yaml, contains('maladies_communes: []')); // slugs left to humans
    expect(yaml, contains('pourquoi_rotation')); // editorial TODO scaffold
  });

  test('warns when a source reports a divergent family name', () async {
    final brouillon = await agregateur(_FakeClient({
      'api.gbif.org': _gbifAutre,
    })).agreger(
      nomScientifique: 'Solanaceae',
      nomCommunFr: 'Solanacées',
      categories: ['legume'],
    );
    expect(
      brouillon.avertissements.any((a) => a.contains('divergente')),
      isTrue,
    );
  });
}
