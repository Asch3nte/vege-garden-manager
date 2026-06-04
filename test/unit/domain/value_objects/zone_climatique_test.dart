import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

void main() {
  group('ZoneRusticite — temperature & frost', () {
    test('numero is 1-based', () {
      expect(ZoneRusticite.zone1.numero, 1);
      expect(ZoneRusticite.zone8.numero, 8);
      expect(ZoneRusticite.zone13.numero, 13);
    });

    test('exposes the coldest extreme-minimum temperature', () {
      expect(ZoneRusticite.zone7.temperatureExtremeMinC, -18);
      expect(ZoneRusticite.zone10.temperatureExtremeMinC, -1);
      expect(ZoneRusticite.zone11.temperatureExtremeMinC, 4);
    });

    test('frost zones are 1..10, frost-free are 11..13', () {
      expect(ZoneRusticite.zone7.connaitLeGel, isTrue);
      expect(ZoneRusticite.zone10.connaitLeGel, isTrue);
      expect(ZoneRusticite.zone11.connaitLeGel, isFalse);
      expect(ZoneRusticite.zone13.connaitLeGel, isFalse);
    });
  });

  group('ZoneClimatique — construction & accessors', () {
    test('exposes its two dimensions', () {
      const z = ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8);
      expect(z.type, TypeClimat.oceanique);
      expect(z.rusticite, ZoneRusticite.zone8);
      expect(z.temperatureExtremeMinC, -12);
    });
  });

  group('ZoneClimatique — supporteGel', () {
    test('true for a cold-tolerant zone', () {
      const z = ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone7);
      expect(z.supporteGel, isTrue);
    });

    test('false for a frost-free zone', () {
      const z = ZoneClimatique(TypeClimat.tropical, ZoneRusticite.zone12);
      expect(z.supporteGel, isFalse);
    });
  });

  group('ZoneClimatique — equality by value', () {
    test('same type and rusticity are equal', () {
      expect(
        const ZoneClimatique(TypeClimat.mediterraneen, ZoneRusticite.zone9),
        const ZoneClimatique(TypeClimat.mediterraneen, ZoneRusticite.zone9),
      );
      expect(
        const ZoneClimatique(TypeClimat.mediterraneen, ZoneRusticite.zone9)
            .hashCode,
        const ZoneClimatique(TypeClimat.mediterraneen, ZoneRusticite.zone9)
            .hashCode,
      );
    });

    test('differing on either dimension breaks equality', () {
      expect(
        const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8) ==
            const ZoneClimatique(TypeClimat.continental, ZoneRusticite.zone8),
        isFalse,
      );
      expect(
        const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8) ==
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone7),
        isFalse,
      );
    });
  });
}
