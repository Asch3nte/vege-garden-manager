import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/bilan_arrosage.dart';
import 'package:pot_a_gerer/application/engine/derivation_sol.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
import 'package:pot_a_gerer/domain/enums/tolerance_secheresse.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';

void main() {
  group('DerivationSol', () {
    const sol = DerivationSol();

    test('texture factor: drains > 1, retains < 1, unknown = 1', () {
      expect(sol.facteurTexture(TextureSol.sableux), greaterThan(1));
      expect(sol.facteurTexture(TextureSol.argileux), lessThan(1));
      expect(sol.facteurTexture(null), 1.0);
    });

    test('technique factor: < 1 when a retaining technique is present', () {
      expect(sol.facteurTechniques({TechniqueSol.paillage}), lessThan(1));
      expect(sol.facteurTechniques({TechniqueSol.grelinette}), 1.0);
      expect(sol.facteurTechniques(const {}), 1.0);
    });
  });

  group('BilanArrosage', () {
    const bilan = BilanArrosage();

    test('high need, neutral soil, dry weather -> water now', () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.eleve,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
      );
      expect(c.urgence, UrgenceArrosage.arroserMaintenant);
      expect(c.joursAvantArrosage, 0);
      expect(c.indiceBesoin, 1.0);
      expect(c.retentionRenforcee, isFalse);
    });

    test('forecast rain defers watering even on a dry day', () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.eleve,
        pluieRecenteMm: 0,
        pluiePrevueMm: 20,
        joursAvantPluie: 1,
        probabilitePluiePrevu: 0.8, // score = 20 * 0.8 = 16 >= 6 → deferred
      );
      expect(c.urgence, UrgenceArrosage.pasNecessaire);
      expect(c.pluiePrevue, isTrue);
      expect(c.joursAvantArrosage, 1);
    });

    test('recent rain keeps the soil moist -> no need', () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.eleve,
        pluieRecenteMm: 25,
        pluiePrevueMm: 0,
      );
      expect(c.urgence, UrgenceArrosage.pasNecessaire);
      expect(c.pluieRecente, isTrue);
    });

    test('moderate need, dry -> water soon', () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.modere, // base 0.65
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
      );
      expect(c.urgence, UrgenceArrosage.bientot);
      expect(c.joursAvantArrosage, BilanArrosage.joursAvantArrosageBientot);
    });

    test('strong retention (clay + mulch + oya) lowers the need below threshold',
        () {
      // eleve 1.0 * 0.75 (argileux) * 0.7 (paillage) * 0.4 (oya) ~ 0.21
      final c = bilan.calculer(
        besoinEau: BesoinEau.eleve,
        texture: TextureSol.argileux,
        techniques: {TechniqueSol.paillage},
        modificateurEquipement: 0.4,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
      );
      expect(c.retentionRenforcee, isTrue);
      expect(c.indiceBesoin, lessThan(BilanArrosage.seuilBientot));
      expect(c.urgence, UrgenceArrosage.pasNecessaire);
    });

    test('works without weather (figures omitted)', () {
      final c = bilan.calculer(besoinEau: BesoinEau.eleve);
      expect(c.pluieRecente, isFalse);
      expect(c.pluiePrevue, isFalse);
      expect(c.urgence, UrgenceArrosage.arroserMaintenant);
    });
  });

  group('BilanArrosage — pondération pluie (Lot 3)', () {
    const bilan = BilanArrosage();

    test('score élevé (20mm × 0.8 = 16) → pluiePrevue=true, watering deferred',
        () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.eleve,
        pluieRecenteMm: 0,
        pluiePrevueMm: 20,
        joursAvantPluie: 1,
        probabilitePluiePrevu: 0.8, // 20 * 0.8 = 16 >= 6
      );
      expect(c.pluiePrevue, isTrue);
      expect(c.urgence, UrgenceArrosage.pasNecessaire);
    });

    test('score faible (10mm × 0.5 = 5.0) → below seuilScorePluie → no defer',
        () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.eleve,
        pluieRecenteMm: 0,
        pluiePrevueMm: 10,
        joursAvantPluie: 1,
        probabilitePluiePrevu: 0.5, // 10 * 0.5 = 5.0 < 6
      );
      expect(c.pluiePrevue, isFalse);
      expect(c.urgence, UrgenceArrosage.arroserMaintenant);
    });

    test('score nul (0mm) → pluiePrevue=false', () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.eleve,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        joursAvantPluie: 1,
        probabilitePluiePrevu: 1.0,
      );
      expect(c.pluiePrevue, isFalse);
    });
  });

  group('BilanArrosage — Lot 4 (sensibilité plante)', () {
    const bilan = BilanArrosage();

    test('faible tolerance → higher demand (modere becomes arroserMaintenant)',
        () {
      // 0.65 * 1.2 = 0.78 >= seuilArroserMaintenant (0.7) → arroserMaintenant
      final c = bilan.calculer(
        besoinEau: BesoinEau.modere,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        toleranceSecheresse: ToleranceSecheresse.faible,
      );
      expect(c.urgence, UrgenceArrosage.arroserMaintenant);
    });

    test('forte tolerance → lower demand (faible stays pasNecessaire)', () {
      // 0.35 * 0.8 = 0.28 < seuilBientot (0.4) → pasNecessaire
      final c = bilan.calculer(
        besoinEau: BesoinEau.faible,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        toleranceSecheresse: ToleranceSecheresse.forte,
      );
      expect(c.urgence, UrgenceArrosage.pasNecessaire);
    });

    test(
        'temperatureMaxTolerance: 28 at 30°C → applies heatwave factor (×1.7)',
        () {
      // Without plant override, 30°C → facteurTempTresChaud (×1.4)
      // With temperatureMaxTolerance=28 and tempMax=30 ≥ 28 → facteurTempCanicule (×1.7)
      // 0.35 * 1.7 = 0.595 → bientot
      final c = bilan.calculer(
        besoinEau: BesoinEau.faible,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        tempMax: 30,
        temperatureMaxTolerance: 28.0,
      );
      expect(c.indiceBesoin, closeTo(0.35 * 1.7, 0.001));
      expect(c.urgence, UrgenceArrosage.bientot);
    });
  });

  group('BilanArrosage — Lot 5 (ET₀)', () {
    test('ET₀ = referenceET0Mm → facteur 1.0', () {
      expect(BilanArrosage.facteurET0(BilanArrosage.referenceET0Mm), 1.0);
    });

    test('ET₀ = 10mm (double reference) → facteur 2.0', () {
      expect(BilanArrosage.facteurET0(10.0), 2.0);
    });

    test('ET₀ disponible prend le dessus sur tempMax', () {
      const bilan = BilanArrosage();
      // et0Mm=10 → facteur 2.0; tempMax=20°C alone would give 1.0 → 0.65
      // With ET₀: 0.65 * 2.0 = 1.3 → clamped to 1.0 → arroserMaintenant
      final c = bilan.calculer(
        besoinEau: BesoinEau.modere,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        tempMax: 20,
        et0Mm: 10,
      );
      expect(c.indiceBesoin, 1.0);
      expect(c.urgence, UrgenceArrosage.arroserMaintenant);
    });
  });

  group('BilanArrosage.facteurTemperature', () {
    test('null -> 1.0 (conservative baseline)', () {
      expect(BilanArrosage.facteurTemperature(null), 1.0);
    });

    test('below 25°C -> 1.0', () {
      expect(BilanArrosage.facteurTemperature(20), 1.0);
      expect(BilanArrosage.facteurTemperature(24.9), 1.0);
    });

    test('25–29°C -> facteurTempChaud', () {
      expect(BilanArrosage.facteurTemperature(25),
          BilanArrosage.facteurTempChaud);
      expect(BilanArrosage.facteurTemperature(29.9),
          BilanArrosage.facteurTempChaud);
    });

    test('30–34°C -> facteurTempTresChaud', () {
      expect(BilanArrosage.facteurTemperature(30),
          BilanArrosage.facteurTempTresChaud);
      expect(BilanArrosage.facteurTemperature(34.9),
          BilanArrosage.facteurTempTresChaud);
    });

    test('>=35°C -> facteurTempCanicule', () {
      expect(BilanArrosage.facteurTemperature(35),
          BilanArrosage.facteurTempCanicule);
      expect(BilanArrosage.facteurTemperature(40),
          BilanArrosage.facteurTempCanicule);
    });
  });

  group('BilanArrosage avec facteur thermique', () {
    const bilan = BilanArrosage();

    test('modere + 36°C heatwave -> water now (was "bientot" without factor)',
        () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.modere, // base 0.65
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        tempMax: 36,
      );
      // 0.65 * 1.7 = 1.105 -> clamped to 1.0 -> arroserMaintenant
      expect(c.urgence, UrgenceArrosage.arroserMaintenant);
      expect(c.indiceBesoin, 1.0);
    });

    test('faible + 36°C + paillage + oya -> still pasNecessaire', () {
      final c = bilan.calculer(
        besoinEau: BesoinEau.faible, // base 0.35
        texture: TextureSol.argileux, // * 0.75
        techniques: {TechniqueSol.paillage}, // * 0.7
        modificateurEquipement: 0.4, // oya
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        tempMax: 36, // * 1.7
      );
      // 0.35 * 0.75 * 0.7 * 0.4 * 1.7 ≈ 0.125 -> pasNecessaire
      expect(c.urgence, UrgenceArrosage.pasNecessaire);
    });

    test('tempMax=null -> same result as no-weather call', () {
      final without = bilan.calculer(
        besoinEau: BesoinEau.modere,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
      );
      final withNull = bilan.calculer(
        besoinEau: BesoinEau.modere,
        pluieRecenteMm: 0,
        pluiePrevueMm: 0,
        tempMax: null,
      );
      expect(withNull.urgence, without.urgence);
      expect(withNull.indiceBesoin, without.indiceBesoin);
    });
  });
}
