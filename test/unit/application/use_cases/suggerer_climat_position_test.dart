import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/use_cases/suggerer_climat_position.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';

class _MockMeteo extends Mock implements AbstractMeteoService {}

void main() {
  late _MockMeteo meteo;
  late SuggererClimatPosition suggerer;
  final briancon = Localisation.gps(latitude: 44.9, longitude: 6.64);

  setUpAll(() => registerFallbackValue(const Localisation.nonDefinie()));

  setUp(() {
    meteo = _MockMeteo();
    suggerer = SuggererClimatPosition(meteo);
  });

  test('refines the suggestion with the altitude when the network is allowed',
      () async {
    when(() => meteo.obtenirElevation(briancon)).thenAnswer((_) async => 1326);
    final s = await suggerer.executer(briancon, reseauAutorise: true);
    expect(s.climat, TypeClimat.montagnard);
    expect(s.rusticite, ZoneRusticite.zone6);
  });

  test('stays on the latitude alone when the network is not allowed',
      () async {
    final s = await suggerer.executer(briancon, reseauAutorise: false);
    expect(s.climat, TypeClimat.mediterraneen);
    expect(s.rusticite, ZoneRusticite.zone7);
    verifyNever(() => meteo.obtenirElevation(any()));
  });

  test('stays on the latitude alone when the altitude is unknown', () async {
    when(() => meteo.obtenirElevation(briancon)).thenAnswer((_) async => null);
    final s = await suggerer.executer(briancon, reseauAutorise: true);
    expect(s.climat, TypeClimat.mediterraneen);
  });
}
