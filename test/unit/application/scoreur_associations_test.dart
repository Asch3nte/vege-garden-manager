import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/scoreur_associations.dart';
import 'package:pot_a_gerer/application/engine/suggestion_association.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_conflit.dart';
import 'package:pot_a_gerer/domain/enums/niveau_confiance.dart';
import 'package:pot_a_gerer/domain/enums/poids_association.dart';
import 'package:pot_a_gerer/domain/enums/type_benefice_association.dart';
import 'package:pot_a_gerer/domain/enums/type_conflit_association.dart';
import 'package:pot_a_gerer/domain/value_objects/profil_ponderation_associations.dart';

SuggestionBenefique _benef(
  TypeBeneficeAssociation m,
  NiveauConfiance c,
) =>
    SuggestionBenefique(cibleId: 'x', mecanisme: m, confiance: c);

void main() {
  const scoreur = ScoreurAssociations();
  final defaut = ProfilPonderationAssociations.defaut();

  group('familleDe — mapping mécanisme → famille', () {
    test('covers each benefit family', () {
      expect(familleDe(TypeBeneficeAssociation.tuteurStructurel),
          FamilleEffetAssociation.gainDePlace);
      expect(familleDe(TypeBeneficeAssociation.repulsionRavageur),
          FamilleEffetAssociation.protectionRavageurs);
      expect(familleDe(TypeBeneficeAssociation.fixationAzote),
          FamilleEffetAssociation.fertilite);
      expect(familleDe(TypeBeneficeAssociation.attractionPollinisateurs),
          FamilleEffetAssociation.pollinisation);
      expect(familleDe(TypeBeneficeAssociation.couvreSol),
          FamilleEffetAssociation.couvertureAbri);
    });

    test('every benefit mechanism maps to a family (exhaustive)', () {
      for (final m in TypeBeneficeAssociation.values) {
        expect(() => familleDe(m), returnsNormally);
      }
    });

    test('ADR-0013 mechanisms join the expected families', () {
      expect(familleDe(TypeBeneficeAssociation.attractionAuxiliaires),
          FamilleEffetAssociation.protectionRavageurs);
      expect(familleDe(TypeBeneficeAssociation.ameublissementSol),
          FamilleEffetAssociation.fertilite);
    });
  });

  group('score — bénéfices pondérés par famille × confiance', () {
    test('default weight (normal) → score equals the confidence factor', () {
      expect(
        scoreur.score(
            _benef(TypeBeneficeAssociation.fixationAzote, NiveauConfiance.eleve),
            defaut),
        ScoreurAssociations.facteurEleve,
      );
      expect(
        scoreur.score(
            _benef(TypeBeneficeAssociation.fixationAzote, NiveauConfiance.faible),
            defaut),
        ScoreurAssociations.facteurFaible,
      );
    });

    test('a heavier family lifts the score (× multiplier)', () {
      final profil = defaut.avec(
          FamilleEffetAssociation.gainDePlace, PoidsAssociation.fort);
      final s = _benef(
          TypeBeneficeAssociation.tuteurStructurel, NiveauConfiance.moyen);
      // 1.5 (fort) × 0.7 (moyen) = 1.05
      expect(scoreur.score(s, profil), closeTo(1.05, 1e-9));
    });

    test('an ignored family scores 0 and is dropped', () {
      final profil = defaut.avec(
          FamilleEffetAssociation.protectionRavageurs, PoidsAssociation.ignore);
      final s = _benef(
          TypeBeneficeAssociation.repulsionRavageur, NiveauConfiance.eleve);
      expect(scoreur.score(s, profil), 0.0);
      expect(scoreur.estRetenue(s, profil), isFalse);
    });

    test('weighting can reorder families (space over protection)', () {
      final profil = defaut
          .avec(FamilleEffetAssociation.gainDePlace, PoidsAssociation.fort)
          .avec(FamilleEffetAssociation.protectionRavageurs, PoidsAssociation.faible);
      final espace = _benef(
          TypeBeneficeAssociation.tuteurStructurel, NiveauConfiance.moyen);
      final protection = _benef(
          TypeBeneficeAssociation.repulsionRavageur, NiveauConfiance.eleve);
      // Despite lower confidence, the valued family wins.
      expect(scoreur.score(espace, profil),
          greaterThan(scoreur.score(protection, profil)));
    });
  });

  group('score — conflits', () {
    final conflit = SuggestionConflit(
        cibleId: 'x',
        mecanisme: TypeConflitAssociation.memeFamilleRavageurs,
        confiance: NiveauConfiance.eleve);

    test('default profile → conflict scored by confidence (weight 1)', () {
      expect(scoreur.score(conflit, defaut), ScoreurAssociations.facteurEleve);
      expect(scoreur.estRetenue(conflit, defaut), isTrue);
    });

    test('its conflict family is weightable by the user (ADR-0014)', () {
      // memeFamilleRavageurs → risque sanitaire; boosting it raises the score.
      final fort = defaut.avecConflit(
          FamilleEffetConflit.risqueSanitaire, PoidsAssociation.fort);
      expect(scoreur.score(conflit, fort),
          greaterThan(scoreur.score(conflit, defaut)));
    });

    test('an ignored conflict family is dropped (ADR-0014)', () {
      final ignore = defaut.avecConflit(
          FamilleEffetConflit.risqueSanitaire, PoidsAssociation.ignore);
      expect(scoreur.score(conflit, ignore), 0);
      expect(scoreur.estRetenue(conflit, ignore), isFalse);
    });
  });
}
