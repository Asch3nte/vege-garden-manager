import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/services/convertisseur_unites.dart';

void main() {
  const c = ConvertisseurUnites();

  void proche(double actuel, double attendu) =>
      expect(actuel, closeTo(attendu, 1e-6));

  test('temperature and temperature difference', () {
    proche(c.celsiusVersFahrenheit(0), 32);
    proche(c.celsiusVersFahrenheit(-40), -40);
    proche(c.celsiusVersFahrenheit(100), 212);
    proche(c.fahrenheitVersCelsius(212), 100);
    proche(c.ecartCelsiusVersFahrenheit(2), 3.6);
  });

  test('length, rain depth and wind speed', () {
    proche(c.centimetresVersPouces(2.54), 1);
    proche(c.poucesVersCentimetres(12), 30.48);
    proche(c.millimetresVersPouces(25.4), 1);
    proche(c.kmhVersMph(1.609344), 1);
    proche(c.metresVersPieds(0.3048), 1);
    proche(c.piedsVersMetres(1), 0.3048);
  });

  test('surface', () {
    proche(c.m2VersFt2(1), 10.763910416709722);
    proche(c.ft2VersM2(10.763910416709722), 1);
  });

  test('volume in US measures', () {
    proche(c.litresVersGallons(3.785411784), 1);
    proche(c.gallonsVersLitres(1), 3.785411784);
    proche(c.millilitresVersOncesLiquides(29.5735295625), 1);
    proche(c.oncesLiquidesVersMillilitres(1), 29.5735295625);
  });

  test('mass', () {
    proche(c.kilogrammesVersLivres(0.45359237), 1);
    proche(c.livresVersKilogrammes(1), 0.45359237);
    proche(c.grammesVersOnces(28.349523125), 1);
    proche(c.oncesVersGrammes(1), 28.349523125);
  });

  test('round trips are exact up to float precision', () {
    for (final v in [0.0, 1.5, 30, 250, -12.3]) {
      proche(
        c.fahrenheitVersCelsius(c.celsiusVersFahrenheit(v.toDouble())),
        v.toDouble(),
      );
      proche(
        c.poucesVersCentimetres(c.centimetresVersPouces(v.toDouble())),
        v.toDouble(),
      );
    }
  });
}
