import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/bilan_arrosage.dart';
import 'package:pot_a_gerer/application/engine/derivation_sol.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
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
}
