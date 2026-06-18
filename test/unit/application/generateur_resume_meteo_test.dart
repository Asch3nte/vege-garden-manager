// Unit tests for the pure weather-text generator engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/generateur_resume_meteo.dart';
import 'package:pot_a_gerer/application/state/jour_meteo_vue.dart';
import 'package:pot_a_gerer/application/state/meteo_accueil_vue.dart';
import 'package:pot_a_gerer/domain/enums/etat_ciel_jour.dart';

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
  const gen = GenerateurResumeMeteo();

  // ── wmoVersEtatCiel ─────────────────────────────────────────────────────

  group('wmoVersEtatCiel', () {
    test('0 → ensoleille', () => expect(gen.wmoVersEtatCiel(0), EtatCielJour.ensoleille));
    test('1 → ensoleille', () => expect(gen.wmoVersEtatCiel(1), EtatCielJour.ensoleille));
    test('2 → nuageux', () => expect(gen.wmoVersEtatCiel(2), EtatCielJour.nuageux));
    test('3 → couvert', () => expect(gen.wmoVersEtatCiel(3), EtatCielJour.couvert));
    test('45 → brouillard', () => expect(gen.wmoVersEtatCiel(45), EtatCielJour.brouillard));
    test('48 → brouillard', () => expect(gen.wmoVersEtatCiel(48), EtatCielJour.brouillard));
    test('51 → pluie (bruine légère)', () => expect(gen.wmoVersEtatCiel(51), EtatCielJour.pluie));
    test('67 → pluie (pluie verglaçante)', () => expect(gen.wmoVersEtatCiel(67), EtatCielJour.pluie));
    test('71 → neige', () => expect(gen.wmoVersEtatCiel(71), EtatCielJour.neige));
    test('77 → neige (grains de neige)', () => expect(gen.wmoVersEtatCiel(77), EtatCielJour.neige));
    test('80 → pluie (averses)', () => expect(gen.wmoVersEtatCiel(80), EtatCielJour.pluie));
    test('82 → pluie (averses violentes)', () => expect(gen.wmoVersEtatCiel(82), EtatCielJour.pluie));
    test('85 → neige (averses neige)', () => expect(gen.wmoVersEtatCiel(85), EtatCielJour.neige));
    test('86 → neige (averses neige fort)', () => expect(gen.wmoVersEtatCiel(86), EtatCielJour.neige));
    test('95 → orage', () => expect(gen.wmoVersEtatCiel(95), EtatCielJour.orage));
    test('99 → orage (grêle)', () => expect(gen.wmoVersEtatCiel(99), EtatCielJour.orage));
    test('code inconnu (100) → couvert par défaut', () {
      expect(gen.wmoVersEtatCiel(100), EtatCielJour.couvert);
    });
  });

  // ── resumeJour ──────────────────────────────────────────────────────────

  group('resumeJour', () {
    test('contains temperature range', () {
      final r = gen.resumeJour(unJour(tempMin: 12, tempMax: 28));
      expect(r, contains('12°'));
      expect(r, contains('28°'));
    });

    test('mentions rain probability and volume when >= 30 %', () {
      final r = gen.resumeJour(unJour(probabilitePluie: 0.5, precipitationsMm: 4.2));
      expect(r, contains('50 % de risque de pluie'));
      expect(r, contains('4.2 mm'));
    });

    test('omits rain section when probability < 30 %', () {
      final r = gen.resumeJour(unJour(probabilitePluie: 0.20));
      expect(r, isNot(contains('pluie')));
    });

    test('mentions gel alert when risqueGel', () {
      final r = gen.resumeJour(unJour(risqueGel: true, tempMin: -2, tempMax: 5));
      expect(r, contains('gel'));
    });

    test('mentions canicule alert when risqueCanicule', () {
      final r = gen.resumeJour(unJour(risqueCanicule: true, tempMin: 25, tempMax: 38));
      expect(r, contains('canicule'));
    });

    test('gel takes priority over canicule label', () {
      // Both set — edge case; gel mention expected, not canicule.
      final r = gen.resumeJour(unJour(risqueGel: true, risqueCanicule: true, tempMin: -2, tempMax: 38));
      expect(r, contains('gel'));
      expect(r, isNot(contains('canicule')));
    });

    test('labels wind "très fort" when >= 50 km/h', () {
      final r = gen.resumeJour(unJour(ventMaxKmh: 55));
      expect(r, contains('Vent très fort'));
    });

    test('labels wind "fort" when >= 30 and < 50 km/h', () {
      final r = gen.resumeJour(unJour(ventMaxKmh: 35));
      expect(r, contains('Vent fort'));
    });

    test('labels wind "modéré" when >= 20 and < 30 km/h', () {
      final r = gen.resumeJour(unJour(ventMaxKmh: 22));
      expect(r, contains('Vent modéré'));
    });

    test('labels wind "faible" when < 20 km/h', () {
      final r = gen.resumeJour(unJour(ventMaxKmh: 8));
      expect(r, contains('Vent faible'));
    });

    test('returns non-empty string for every WMO state', () {
      for (final code in [0, 2, 3, 45, 61, 71, 80, 85, 95]) {
        expect(gen.resumeJour(unJour(weathercode: code)), isNotEmpty,
            reason: 'WMO $code should produce a non-empty summary');
      }
    });
  });

  // ── resumeDemain ────────────────────────────────────────────────────────

  group('resumeDemain', () {
    test('returns null when demain is null', () {
      expect(gen.resumeDemain(null), isNull);
    });

    test('contains max temperature', () {
      final r = gen.resumeDemain(unJour(tempMax: 22));
      expect(r, isNotNull);
      expect(r, contains('22°'));
    });

    test('mentions rain probability when >= 30 %', () {
      final r = gen.resumeDemain(unJour(probabilitePluie: 0.6, precipitationsMm: 3.0));
      expect(r, isNotNull);
      expect(r, contains('60 % de risque de pluie'));
      expect(r, contains('3.0 mm'));
    });

    test('omits rain section when probability < 30 %', () {
      final r = gen.resumeDemain(unJour(probabilitePluie: 0.10));
      expect(r, isNotNull);
      expect(r, isNot(contains('pluie')));
    });

    test('ends with a period', () {
      final r = gen.resumeDemain(unJour());
      expect(r, isNotNull);
      expect(r!.endsWith('.'), isTrue);
    });
  });

  // ── explicationTaches ───────────────────────────────────────────────────

  group('explicationTaches', () {
    for (final verdict in VerdictMeteo.values) {
      test('returns non-empty string for $verdict', () {
        expect(gen.explicationTaches(verdict), isNotEmpty);
      });
    }

    test('pluieAVenir → mentions tasks being deferred', () {
      expect(gen.explicationTaches(VerdictMeteo.pluieAVenir), contains('différées'));
    });

    test('solHumide → mentions moist soil', () {
      expect(gen.explicationTaches(VerdictMeteo.solHumide), contains('humide'));
    });

    test('arroserConseille → mentions watering need', () {
      expect(gen.explicationTaches(VerdictMeteo.arroserConseille), contains('arrosage'));
    });

    test('clement → mentions plant water needs', () {
      expect(gen.explicationTaches(VerdictMeteo.clement), contains('eau'));
    });
  });
}
