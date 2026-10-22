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
  var reseau = true;
  final briancon = Localisation.gps(latitude: 44.9, longitude: 6.64);

  setUpAll(() => registerFallbackValue(const Localisation.nonDefinie()));

  setUp(() {
    meteo = _MockMeteo();
    reseau = true;
  });

  SuggererClimatPosition suggerer() =>
      SuggererClimatPosition(meteo, () => reseau);

  test('refines the suggestion with the altitude when the network is allowed',
      () async {
    when(() => meteo.obtenirElevation(briancon)).thenAnswer((_) async => 1326);
    final s = await suggerer().executer(briancon);
    expect(s!.climat, TypeClimat.montagnard);
    expect(s.rusticite, ZoneRusticite.zone6);
  });

  test('sends nothing and suggests nothing with the network opt-out',
      () async {
    reseau = false;
    expect(await suggerer().executer(briancon), isNull);
    verifyNever(() => meteo.obtenirElevation(any()));
  });

  test('suggests nothing when the altitude is unknown', () async {
    when(() => meteo.obtenirElevation(briancon)).thenAnswer((_) async => null);
    expect(await suggerer().executer(briancon), isNull);
  });
}
