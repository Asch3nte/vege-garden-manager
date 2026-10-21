import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/teinte_zone.dart';
import 'package:pot_a_gerer/domain/exceptions/invariant_domaine_exception.dart';
import 'package:pot_a_gerer/domain/value_objects/couleur_zone.dart';

void main() {
  group('CouleurZone', () {
    test('a palette tint is not custom', () {
      const c = CouleurZone.teinte(TeinteZone.aubergine);
      expect(c.teinte, TeinteZone.aubergine);
      expect(c.rgb, isNull);
      expect(c.estPersonnalisee, isFalse);
    });

    test('a custom colour keeps its 24-bit RGB value', () {
      final c = CouleurZone.personnalisee(0x3366CC);
      expect(c.rgb, 0x3366CC);
      expect(c.teinte, isNull);
      expect(c.estPersonnalisee, isTrue);
    });

    test('a custom colour outside 24 bits is refused', () {
      expect(
        () => CouleurZone.personnalisee(-1),
        throwsA(isA<InvariantDomaineException>()),
      );
      expect(
        () => CouleurZone.personnalisee(0x1000000),
        throwsA(isA<InvariantDomaineException>()),
      );
    });

    test('equality is by value', () {
      expect(
        const CouleurZone.teinte(TeinteZone.terre),
        const CouleurZone.teinte(TeinteZone.terre),
      );
      expect(
        CouleurZone.personnalisee(0x123456),
        CouleurZone.personnalisee(0x123456),
      );
      expect(
        CouleurZone.personnalisee(0x123456),
        isNot(CouleurZone.personnalisee(0x123457)),
      );
      expect(
        const CouleurZone.teinte(TeinteZone.terre),
        isNot(const CouleurZone.teinte(TeinteZone.bordeaux)),
      );
    });

    group('suivante', () {
      test('first tint when the garden has no zone', () {
        expect(
          CouleurZone.suivante(const []),
          CouleurZone.teinte(TeinteZone.values.first),
        );
      });

      test('first tint not yet used, in palette order', () {
        expect(
          CouleurZone.suivante([
            const CouleurZone.teinte(TeinteZone.vertProfond),
            const CouleurZone.teinte(TeinteZone.aubergine),
            CouleurZone.personnalisee(0x000000),
          ]),
          const CouleurZone.teinte(TeinteZone.terracotta),
        );
      });

      test('cycles on the zone count once every tint is used', () {
        final toutes = [
          for (final t in TeinteZone.values) CouleurZone.teinte(t),
        ];
        expect(
          CouleurZone.suivante(toutes),
          CouleurZone.teinte(TeinteZone.values.first),
        );
        expect(
          CouleurZone.suivante([
            ...toutes,
            const CouleurZone.teinte(TeinteZone.terre),
          ]),
          CouleurZone.teinte(TeinteZone.values[1]),
        );
      });
    });

    test('pour un index reproduces the former positional colour', () {
      expect(
        [for (var i = 0; i < 7; i++) CouleurZone.pourIndex(i).teinte],
        [...TeinteZone.values, TeinteZone.values.first],
      );
    });
  });
}
