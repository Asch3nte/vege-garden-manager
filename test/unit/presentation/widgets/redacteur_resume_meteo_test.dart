import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pot_a_gerer/application/state/jour_meteo_vue.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_vue.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/redacteur_resume_meteo.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';
import 'package:pot_a_gerer/presentation/widgets/formateur_mesures.dart';

JourMeteoVue unJour({
  int weathercode = 0,
  double tempMin = 15,
  double tempMax = 25,
  double probabilitePluie = 0,
  double precipitationsMm = 0,
  double ventMaxKmh = 10,
  bool risqueGel = false,
  bool risqueCanicule = false,
}) =>
    JourMeteoVue(
      date: DateTime(2026, 6, 18),
      tempMin: tempMin,
      tempMax: tempMax,
      precipitationsMm: precipitationsMm,
      probabilitePluie: probabilitePluie,
      weathercode: weathercode,
      risqueGel: risqueGel,
      risqueCanicule: risqueCanicule,
      ventMaxKmh: ventMaxKmh,
      heures: const [],
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
  });

  RedacteurResumeMeteo redacteur(String langue,
      [PreferencesUnites unites = const PreferencesUnites()]) {
    final l10n = lookupAppLocalizations(Locale(langue));
    return RedacteurResumeMeteo(l10n, FormateurMesures(l10n, unites));
  }

  final fr = redacteur('fr');
  final en = redacteur('en');

  group('resumeJour', () {
    test('full French sentence', () {
      expect(fr.resumeJour(unJour(tempMin: 18, tempMax: 26)),
          'Temps ensoleillé. Min 18°, max 26°. Vent faible (10 km/h).');
    });

    test('rain probability and locale-formatted volume when >= 30 %', () {
      final r = fr.resumeJour(unJour(probabilitePluie: 0.5, precipitationsMm: 4.2));
      expect(r, contains('50 % de risque de pluie (4,2 mm).'));
      expect(en.resumeJour(unJour(probabilitePluie: 0.5, precipitationsMm: 4.2)),
          contains('4.2 mm'));
    });

    test('omits rain below 30 %', () {
      expect(fr.resumeJour(unJour(probabilitePluie: 0.2)),
          isNot(contains('pluie')));
    });

    test('frost takes priority over heatwave', () {
      final r = fr.resumeJour(unJour(risqueGel: true, risqueCanicule: true));
      expect(r, contains('gel'));
      expect(r, isNot(contains('canicule')));
      expect(fr.resumeJour(unJour(risqueCanicule: true)), contains('canicule'));
    });

    test('wind strength thresholds', () {
      expect(fr.resumeJour(unJour(ventMaxKmh: 55)), contains('Vent très fort'));
      expect(fr.resumeJour(unJour(ventMaxKmh: 35)), contains('Vent fort ('));
      expect(fr.resumeJour(unJour(ventMaxKmh: 22)), contains('Vent modéré'));
      expect(fr.resumeJour(unJour(ventMaxKmh: 8)), contains('Vent faible'));
    });

    test('English output carries no French', () {
      final r = en.resumeJour(unJour(weathercode: 61, risqueGel: true,
          probabilitePluie: 0.6, precipitationsMm: 2, ventMaxKmh: 40));
      expect(r, isNot(matches(RegExp('Pluie|gel|Vent|risque'))));
    });
  });

  test('imperial units convert temperatures, rain and wind', () {
    final imperial =
        redacteur('en', const PreferencesUnites.uniforme(SystemeUnites.imperial));
    expect(
      imperial.resumeJour(unJour(
          tempMin: 0,
          tempMax: 20,
          probabilitePluie: 0.5,
          precipitationsMm: 25.4,
          ventMaxKmh: 16.09344)),
      allOf(contains('32°'), contains('68°'), contains('1 in'),
          contains('10 mph')),
    );
  });

  group('resumeDemain', () {
    test('short outlook with rain', () {
      expect(
          fr.resumeDemain(
              unJour(weathercode: 61, tempMax: 22, probabilitePluie: 0.8,
                  precipitationsMm: 2)),
          'Pluvieux, max 22°, 80 % de risque de pluie (2 mm).');
    });

    test('without rain', () {
      expect(fr.resumeDemain(unJour(tempMax: 22)), 'Ensoleillé, max 22°.');
    });
  });

  group('explicationTaches', () {
    for (final verdict in VerdictMeteo.values) {
      test('${verdict.name} has a text in both languages', () {
        expect(fr.explicationTaches(verdict), isNotEmpty);
        expect(en.explicationTaches(verdict), isNot(fr.explicationTaches(verdict)));
      });
    }
  });
}
