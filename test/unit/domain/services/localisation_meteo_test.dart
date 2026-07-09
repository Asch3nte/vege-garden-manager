import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/services/localisation_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';

void main() {
  final position = Localisation.gps(latitude: 48.85, longitude: 2.35);

  test('weather on → returns the position unchanged', () {
    final loc = localisationPourMeteo(position, meteoAutoActive: true);
    expect(loc.estDefinie, isTrue);
    expect(loc.latitude, 48.85);
  });

  test('weather off → returns an undefined location (no coordinates)', () {
    final loc = localisationPourMeteo(position, meteoAutoActive: false);
    expect(loc.estDefinie, isFalse);
  });

  test('weather off with an already-undefined position stays undefined', () {
    final loc = localisationPourMeteo(const Localisation.nonDefinie(),
        meteoAutoActive: false);
    expect(loc.estDefinie, isFalse);
  });
}
