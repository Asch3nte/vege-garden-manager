// Unit tests for the location-to-climate derivation (coarse suggestions).
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/derivateur_localisation.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';

void main() {
  const derivateur = DerivateurLocalisation();

  Localisation pos(double lat) =>
      Localisation.gps(latitude: lat, longitude: 0);

  test('northern latitude → northern hemisphere', () {
    expect(derivateur.deriver(pos(48.85)).hemisphere, Hemisphere.nord);
  });

  test('southern latitude → southern hemisphere', () {
    expect(derivateur.deriver(pos(-33.9)).hemisphere, Hemisphere.sud);
  });

  test('temperate latitude suggests an oceanic climate, mid hardiness', () {
    final s = derivateur.deriver(pos(48.85)); // Paris-ish
    expect(s.climat, TypeClimat.oceanique);
    expect(s.rusticite, ZoneRusticite.zone6);
  });

  test('tropical latitude suggests a tropical climate, warm hardiness', () {
    final s = derivateur.deriver(pos(1.3)); // near the equator
    expect(s.climat, TypeClimat.tropical);
    expect(s.rusticite, ZoneRusticite.zone11);
  });

  test('the southern hemisphere uses the absolute latitude for bands', () {
    final s = derivateur.deriver(pos(-48.85));
    expect(s.hemisphere, Hemisphere.sud);
    expect(s.climat, TypeClimat.oceanique);
  });

  test('an undefined position is rejected', () {
    expect(
      () => derivateur.deriver(const Localisation.nonDefinie()),
      throwsArgumentError,
    );
  });

  group('altitude', () {
    test('without altitude, the latitude bands are unchanged', () {
      final s = derivateur.deriver(pos(42), altitudeM: null);
      expect(s.climat, TypeClimat.mediterraneen);
      expect(s.rusticite, ZoneRusticite.zone7);
    });

    test('below 800 m nothing changes', () {
      final s = derivateur.deriver(pos(42), altitudeM: 790);
      expect(s.climat, TypeClimat.mediterraneen);
      expect(s.rusticite, ZoneRusticite.zone7);
    });

    test('each 800 m lowers the hardiness by one zone', () {
      expect(derivateur.deriver(pos(42), altitudeM: 1000).rusticite,
          ZoneRusticite.zone6);
      expect(derivateur.deriver(pos(42), altitudeM: 1650).rusticite,
          ZoneRusticite.zone5);
    });

    test('from 1200 m the climate is mountain', () {
      expect(derivateur.deriver(pos(42), altitudeM: 1199).climat,
          TypeClimat.mediterraneen);
      expect(derivateur.deriver(pos(42), altitudeM: 1200).climat,
          TypeClimat.montagnard);
    });

    test('a polar climate stays polar at altitude', () {
      expect(derivateur.deriver(pos(70), altitudeM: 2000).climat,
          TypeClimat.polaire);
    });

    test('the hardiness never goes below the coldest zone', () {
      expect(derivateur.deriver(pos(70), altitudeM: 9000).rusticite,
          ZoneRusticite.values.first);
    });

    test('a negative altitude changes nothing', () {
      expect(derivateur.deriver(pos(42), altitudeM: -30).rusticite,
          ZoneRusticite.zone7);
    });
  });
}
