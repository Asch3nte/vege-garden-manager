import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/glossaire/liens_glossaire.dart';

void main() {
  group('analyserLiensGlossaire', () {
    test('plain text yields a single raw segment', () {
      expect(
        analyserLiensGlossaire('Un texte sans lien.'),
        [const SegmentBrut('Un texte sans lien.')],
      );
    });

    test('empty text yields no segment', () {
      expect(analyserLiensGlossaire(''), isEmpty);
    });

    test('a bare link uses its id as label', () {
      expect(
        analyserLiensGlossaire('Voir [[notion.compagnonnage]].'),
        [
          const SegmentBrut('Voir '),
          const SegmentLien('notion.compagnonnage', 'notion.compagnonnage'),
          const SegmentBrut('.'),
        ],
      );
    });

    test('a labelled link keeps its display text', () {
      expect(
        analyserLiensGlossaire('la [[notion.rotation-cultures|rotation]] aide'),
        [
          const SegmentBrut('la '),
          const SegmentLien('notion.rotation-cultures', 'rotation'),
          const SegmentBrut(' aide'),
        ],
      );
    });

    test('multiple links are split in order and cover the whole input', () {
      final segments = analyserLiensGlossaire(
          '[[famille.solanaceae|Solanacées]] et [[bio.mildiou]]');
      expect(segments, [
        const SegmentLien('famille.solanaceae', 'Solanacées'),
        const SegmentBrut(' et '),
        const SegmentLien('bio.mildiou', 'bio.mildiou'),
      ]);
      // No character lost: concatenating display texts rebuilds a full text.
      expect(segments.map((s) => s.texte).join(),
          'Solanacées et bio.mildiou');
    });

    test('id and label are trimmed', () {
      expect(
        analyserLiensGlossaire('[[ bio.mildiou | le mildiou ]]'),
        [const SegmentLien('bio.mildiou', 'le mildiou')],
      );
    });

    test('malformed constructs stay verbatim as plain text', () {
      expect(
        analyserLiensGlossaire('un [[lien jamais fermé et [seul] crochet'),
        [const SegmentBrut('un [[lien jamais fermé et [seul] crochet')],
      );
    });

    test('blank id or label keeps the raw construct as plain text', () {
      final segments = analyserLiensGlossaire('[[ ]] et [[id| ]]');
      // Adjacent raw segments are not merged; what matters is that no link is
      // produced and no character is lost.
      expect(segments.whereType<SegmentLien>(), isEmpty);
      expect(segments.map((s) => s.texte).join(), '[[ ]] et [[id| ]]');
    });

    test('the segment list is unmodifiable', () {
      expect(
        () => analyserLiensGlossaire('texte').add(const SegmentBrut('x')),
        throwsUnsupportedError,
      );
    });
  });

  group('extraireIdsLiens', () {
    test('collects link ids in order, keeping duplicates', () {
      expect(
        extraireIdsLiens('[[a.b]] puis [[c.d|libellé]] puis [[a.b]]'),
        ['a.b', 'c.d', 'a.b'],
      );
    });

    test('is empty for plain text', () {
      expect(extraireIdsLiens('rien ici'), isEmpty);
    });
  });
}
