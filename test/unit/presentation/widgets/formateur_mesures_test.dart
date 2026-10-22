import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/dimensions_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';
import 'package:pot_a_gerer/l10n/app_localizations_en.dart';
import 'package:pot_a_gerer/l10n/app_localizations_fr.dart';
import 'package:pot_a_gerer/presentation/widgets/formateur_mesures.dart';

void main() {
  final metrique = FormateurMesures(AppLocalizationsFr(), PreferencesUnites());
  final imperial = FormateurMesures(
    AppLocalizationsEn(),
    const PreferencesUnites.uniforme(SystemeUnites.imperial),
  );

  test('temperatures', () {
    expect(metrique.temperature(21.4), '21 °C');
    expect(imperial.temperature(21.4), '71 °F');
    expect(metrique.degres(-2.6), '-3');
    expect(imperial.degres(0), '32');
    expect(metrique.symboleTemperature, '°C');
    expect(imperial.symboleTemperature, '°F');
    expect(metrique.ecartTemperature(2), '2 °C');
    expect(imperial.ecartTemperature(2), '3.6 °F');
  });

  test('zone dimensions in metres or feet', () {
    final d = DimensionsZone(longueurCm: 300, largeurCm: 120);
    expect(metrique.dimensionsZone(d), '3 × 1,2 m');
    expect(imperial.dimensionsZone(d), '9.8 × 3.9 ft');
  });

  test('lengths: inches under a foot, then feet and inches', () {
    expect(metrique.longueurCm(30), '30 cm');
    expect(imperial.longueurCm(15), '5.9 in');
    expect(imperial.longueurCm(30.48), '1 ft');
    expect(imperial.longueurCm(40), '1 ft 4 in');
    expect(imperial.longueurCm(30.2), '11.9 in');
  });

  test('small lengths keep a decimal', () {
    expect(metrique.longueurCm(0.5), '0,5 cm');
    expect(imperial.longueurCm(1), '0.4 in');
  });

  test('a value rounding up to the threshold switches unit', () {
    expect(metrique.masseG(999.6), '1 kg');
    expect(imperial.masseG(453), '1 lb');
    expect(imperial.volumeMl(3785), '1 gal');
  });

  test('rain, wind and watering depth follow the length setting', () {
    expect(metrique.precipitations(1.25), '1,3 mm');
    expect(metrique.precipitations(2), '2 mm');
    expect(imperial.precipitations(12.7), '0.5 in');
    expect(metrique.vent(19.6), '20 km/h');
    expect(imperial.vent(16.09344), '10 mph');
    expect(metrique.arrosage(3), '3 L/m²');
    expect(imperial.arrosage(5.08), '0.2 in');
  });

  test('ranges keep the metric wording, imperial spells each bound', () {
    expect(metrique.plageLongueurCm(15, 30), '15–30 cm');
    expect(imperial.plageLongueurCm(15, 40), '5.9 in – 1 ft 4 in');
    expect(metrique.plageArrosage(3, 5), '3 à 5 L/m²');
    expect(imperial.plageArrosage(2.54, 5.08), '0.1 to 0.2 in');
  });

  test('elevation', () {
    expect(metrique.altitudeM(65.4), '65 m');
    expect(imperial.altitudeM(30.48), '100 ft');
  });

  test('areas', () {
    expect(metrique.surfaceM2(2.5), '2,5 m²');
    expect(metrique.surfaceM2(0.25), '0,25 m²');
    expect(imperial.surfaceM2(1), '10.8 ft²');
  });

  test('masses: small unit under the big one', () {
    expect(metrique.masseG(850), '850 g');
    expect(metrique.masseG(1250), '1,3 kg');
    expect(imperial.masseG(100), '3.5 oz');
    expect(imperial.masseG(1000), '2.2 lb');
  });

  test('volumes: small unit under the big one', () {
    expect(metrique.volumeMl(250), '250 mL');
    expect(metrique.volumeMl(1500), '1,5 L');
    expect(imperial.volumeMl(250), '8.5 fl oz');
    expect(imperial.volumeMl(7570.82), '2 gal');
  });
}
