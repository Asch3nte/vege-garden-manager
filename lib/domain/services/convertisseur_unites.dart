/// Conversions between metric and US customary units. Data is stored in
/// metric; these serve display and input only.
class ConvertisseurUnites {
  static const double _cmParPouce = 2.54;
  static const double _mmParPouce = 25.4;
  static const double _kmParMille = 1.609344;
  static const double _mParPied = 0.3048;
  static const double _m2ParFt2 = 0.09290304;
  static const double _litresParGallon = 3.785411784;
  static const double _mlParOnceLiquide = 29.5735295625;
  static const double _kgParLivre = 0.45359237;
  static const double _gParOnce = 28.349523125;

  const ConvertisseurUnites();

  double celsiusVersFahrenheit(double c) => c * 9 / 5 + 32;
  double fahrenheitVersCelsius(double f) => (f - 32) * 5 / 9;

  /// A temperature difference (e.g. +2 °C of shelter), without the offset.
  double ecartCelsiusVersFahrenheit(double c) => c * 9 / 5;

  double centimetresVersPouces(double cm) => cm / _cmParPouce;
  double poucesVersCentimetres(double pouces) => pouces * _cmParPouce;
  double millimetresVersPouces(double mm) => mm / _mmParPouce;
  double kmhVersMph(double kmh) => kmh / _kmParMille;
  double metresVersPieds(double m) => m / _mParPied;

  double m2VersFt2(double m2) => m2 / _m2ParFt2;
  double ft2VersM2(double ft2) => ft2 * _m2ParFt2;

  double litresVersGallons(double litres) => litres / _litresParGallon;
  double gallonsVersLitres(double gallons) => gallons * _litresParGallon;
  double millilitresVersOncesLiquides(double ml) => ml / _mlParOnceLiquide;
  double oncesLiquidesVersMillilitres(double onces) =>
      onces * _mlParOnceLiquide;

  double kilogrammesVersLivres(double kg) => kg / _kgParLivre;
  double livresVersKilogrammes(double livres) => livres * _kgParLivre;
  double grammesVersOnces(double g) => g / _gParOnce;
  double oncesVersGrammes(double onces) => onces * _gParOnce;
}
