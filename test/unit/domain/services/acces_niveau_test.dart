import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/services/acces_niveau.dart';

void main() {
  const debutant = AccesNiveau(NiveauExperience.debutant);
  const intermediaire = AccesNiveau(NiveauExperience.intermediaire);
  const expert = AccesNiveau(NiveauExperience.expert);

  group('Débutant — core only', () {
    test('intermediate and expert features are locked', () {
      expect(debutant.vueReseau, isFalse);
      expect(debutant.equipements, isFalse);
      expect(debutant.observations, isFalse);
      expect(debutant.vueSaison, isFalse);
      expect(debutant.multiPotager, isFalse);
      expect(debutant.notificationsParCategorie, isFalse);
      expect(debutant.solTexturePh, isFalse);
      expect(debutant.statsTableauBord, isFalse);
      expect(debutant.eauDetaillee, isFalse);
    });
  });

  group('Intermédiaire', () {
    test('unlocks the intermediate tier but not the expert one', () {
      expect(intermediaire.vueReseau, isTrue);
      expect(intermediaire.equipements, isTrue);
      expect(intermediaire.observations, isTrue);
      expect(intermediaire.vueSaison, isTrue);
      expect(intermediaire.multiPotager, isTrue);
      expect(intermediaire.notificationsParCategorie, isTrue);
      expect(intermediaire.calendrierLunaire, isTrue);
      // Still expert-only:
      expect(intermediaire.solTexturePh, isFalse);
      expect(intermediaire.statsTableauBord, isFalse);
      expect(intermediaire.rotationAvancee, isFalse);
      expect(intermediaire.fichesPerso, isFalse);
      expect(intermediaire.eauDetaillee, isFalse);
    });
  });

  group('Expert — everything open', () {
    test('expert-tier features are unlocked', () {
      expect(expert.solTexturePh, isTrue);
      expect(expert.statsTableauBord, isTrue);
      expect(expert.rotationAvancee, isTrue);
      expect(expert.fichesPerso, isTrue);
      expect(expert.eauDetaillee, isTrue);
      expect(expert.vueReseau, isTrue);
    });
  });

  group('palierSuivant (level-up teaser target)', () {
    test('climbs débutant → intermédiaire → expert → null', () {
      expect(debutant.palierSuivant, NiveauExperience.intermediaire);
      expect(intermediaire.palierSuivant, NiveauExperience.expert);
      expect(expert.palierSuivant, isNull);
    });
  });
}
