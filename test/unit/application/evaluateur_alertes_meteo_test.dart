import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/evaluateur_alertes_meteo.dart';
import 'package:pot_a_gerer/domain/enums/type_alerte_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';

void main() {
  const evaluateur = EvaluateurAlertesMeteo();

  PrevisionMeteo prev({
    required DateTime date,
    double tempMin = 12,
    double tempMax = 22,
    double precip = 0,
  }) =>
      PrevisionMeteo(
        date: date,
        tempMin: tempMin,
        tempMax: tempMax,
        precipitationsMm: precip,
      );

  test('flags nothing for a calm day', () {
    final r = evaluateur.evaluer([prev(date: DateTime.utc(2026, 6, 10))]);
    expect(r, isEmpty);
  });

  test('flags frost when tempMin is at or below 0', () {
    final r = evaluateur.evaluer([
      prev(date: DateTime.utc(2026, 1, 10), tempMin: 0), // boundary included
      prev(date: DateTime.utc(2026, 1, 11), tempMin: -3),
    ]);
    expect(r.map((e) => e.type), everyElement(TypeAlerteMeteo.gel));
    expect(r, hasLength(2));
    expect(r.first.valeur, 0);
  });

  test('flags heatwave when tempMax is at or above 35', () {
    final r = evaluateur.evaluer([
      prev(date: DateTime.utc(2026, 7, 1), tempMax: 35), // boundary included
      prev(date: DateTime.utc(2026, 7, 2), tempMax: 34.9), // below -> nothing
    ]);
    expect(r, hasLength(1));
    expect(r.single.type, TypeAlerteMeteo.canicule);
    expect(r.single.valeur, 35);
  });

  test('flags heavy rain when precipitation is at or above 30 mm', () {
    final r = evaluateur.evaluer([
      prev(date: DateTime.utc(2026, 9, 1), precip: 30), // boundary included
      prev(date: DateTime.utc(2026, 9, 2), precip: 29.9),
    ]);
    expect(r, hasLength(1));
    expect(r.single.type, TypeAlerteMeteo.fortePluie);
    expect(r.single.valeur, 30);
  });

  test('a single day can raise several risks (frost + heavy rain)', () {
    final r = evaluateur.evaluer([
      prev(date: DateTime.utc(2026, 3, 1), tempMin: -1, precip: 40),
    ]);
    expect(r.map((e) => e.type),
        containsAll([TypeAlerteMeteo.gel, TypeAlerteMeteo.fortePluie]));
    expect(r, hasLength(2));
  });

  test('the result is unmodifiable', () {
    final r = evaluateur.evaluer([prev(date: DateTime.utc(2026, 1, 1), tempMin: -1)]);
    expect(() => r.clear(), throwsUnsupportedError);
  });
}
