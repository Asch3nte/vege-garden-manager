import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/groupe_cultural.dart';
import 'package:pot_a_gerer/domain/value_objects/precedent_cultural.dart';

void main() {
  group('PrecedentCultural — factories & invariants', () {
    test('famille exposes the slug and is not a group', () {
      final p = PrecedentCultural.famille('solanaceae');
      expect(p.estFamille, isTrue);
      expect(p.estGroupe, isFalse);
      expect(p.familleSlug, 'solanaceae');
      expect(p.groupe, isNull);
    });

    test('groupe exposes the group and is not a family', () {
      const p = PrecedentCultural.groupe(GroupeCultural.legumineuses);
      expect(p.estGroupe, isTrue);
      expect(p.estFamille, isFalse);
      expect(p.groupe, GroupeCultural.legumineuses);
      expect(p.familleSlug, isNull);
    });

    test('famille rejects an empty slug', () {
      expect(
        () => PrecedentCultural.famille(''),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PrecedentCultural.analyser — functional groups', () {
    test('legumineuses maps to the legumes group', () {
      expect(PrecedentCultural.analyser('legumineuses'),
          const PrecedentCultural.groupe(GroupeCultural.legumineuses));
    });

    test('engrais_verts and engrais_vert both map to green manures', () {
      const green = PrecedentCultural.groupe(GroupeCultural.engraisVerts);
      expect(PrecedentCultural.analyser('engrais_verts'), green);
      expect(PrecedentCultural.analyser('engrais_vert'), green);
    });

    test('a space- or hyphen-separated group token is folded', () {
      const green = PrecedentCultural.groupe(GroupeCultural.engraisVerts);
      expect(PrecedentCultural.analyser('engrais verts'), green);
      expect(PrecedentCultural.analyser('engrais-verts'), green);
    });
  });

  group('PrecedentCultural.analyser — family spelling drift', () {
    test('clean family slug is kept as-is', () {
      expect(PrecedentCultural.analyser('solanaceae'),
          PrecedentCultural.famille('solanaceae'));
    });

    test('French misspellings are canonicalized to the family slug', () {
      expect(PrecedentCultural.analyser('cucurbitacees'),
          PrecedentCultural.famille('cucurbitaceae'));
      expect(PrecedentCultural.analyser('brassicacees'),
          PrecedentCultural.famille('brassicaceae'));
    });

    test('accented "graminées" maps to poaceae', () {
      expect(PrecedentCultural.analyser('graminées'),
          PrecedentCultural.famille('poaceae'));
      // Un-accented spelling resolves identically.
      expect(PrecedentCultural.analyser('graminees'),
          PrecedentCultural.famille('poaceae'));
    });

    test('common name "ail" maps to amaryllidaceae', () {
      expect(PrecedentCultural.analyser('ail'),
          PrecedentCultural.famille('amaryllidaceae'));
    });

    test('unknown family token is normalized but preserved', () {
      // Not an alias: kept as a (lowercased, accent-free) family slug. Whether
      // it resolves to a real _familles/*.yaml is an infra concern, not here.
      final p = PrecedentCultural.analyser('Rosaceae');
      expect(p!.estFamille, isTrue);
      expect(p.familleSlug, 'rosaceae');
    });
  });

  group('PrecedentCultural.analyser — blanks', () {
    test('empty or whitespace-only token yields null', () {
      expect(PrecedentCultural.analyser(''), isNull);
      expect(PrecedentCultural.analyser('   '), isNull);
      expect(PrecedentCultural.analyser('__'), isNull);
    });
  });

  group('PrecedentCultural — value equality', () {
    test('same family slugs are equal and share a hash', () {
      final a = PrecedentCultural.famille('fabaceae');
      final b = PrecedentCultural.analyser('fabaceae');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('same group values are equal', () {
      expect(const PrecedentCultural.groupe(GroupeCultural.legumineuses),
          const PrecedentCultural.groupe(GroupeCultural.legumineuses));
    });

    test('a family and a group never collide', () {
      expect(PrecedentCultural.famille('fabaceae'),
          isNot(const PrecedentCultural.groupe(GroupeCultural.legumineuses)));
    });

    test('deduplicates inside a Set regardless of the raw spelling', () {
      final set = {
        PrecedentCultural.analyser('cucurbitacees')!,
        PrecedentCultural.analyser('cucurbitaceae')!,
        PrecedentCultural.analyser('legumineuses')!,
      };
      expect(set.length, 2);
    });
  });
}
