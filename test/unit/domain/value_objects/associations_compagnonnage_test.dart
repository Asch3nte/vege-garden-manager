import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/type_benefice_association.dart';
import 'package:pot_a_gerer/domain/enums/type_conflit_association.dart';
import 'package:pot_a_gerer/domain/value_objects/association_benefique.dart';
import 'package:pot_a_gerer/domain/value_objects/association_conflit.dart';

void main() {
  group('multi-mécanismes & familles (ADR-0012)', () {
    test('une paire peut porter plusieurs mécanismes', () {
      final a = AssociationBenefique(cibleId: 'x', mecanismes: {
        TypeBeneficeAssociation.brouillageOlfactif,
        TypeBeneficeAssociation.repulsionRavageur,
      });
      expect(a.mecanismes, hasLength(2));
      expect(a.aMecanisme, isTrue);
      // Convenience `mecanisme` returns the first (ADR-0010 compat).
      expect(a.mecanisme, isNotNull);
    });

    test('mecanisme simple = ensemble singleton', () {
      final a = AssociationBenefique(
          cibleId: 'x', mecanisme: TypeBeneficeAssociation.fixationAzote);
      expect(a.mecanismes, {TypeBeneficeAssociation.fixationAzote});
      expect(a.mecanisme, TypeBeneficeAssociation.fixationAzote);
    });

    test('égalité indépendante de l ordre des mécanismes', () {
      final a = AssociationBenefique(cibleId: 'x', mecanismes: {
        TypeBeneficeAssociation.couvreSol,
        TypeBeneficeAssociation.briseVent,
      });
      final b = AssociationBenefique(cibleId: 'x', mecanismes: {
        TypeBeneficeAssociation.briseVent,
        TypeBeneficeAssociation.couvreSol,
      });
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('refuse mecanisme ET mecanismes ensemble', () {
      expect(
        () => AssociationBenefique(
          cibleId: 'x',
          mecanisme: TypeBeneficeAssociation.couvreSol,
          mecanismes: {TypeBeneficeAssociation.briseVent},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('AssociationConflit gère aussi plusieurs mécanismes', () {
      final c = AssociationConflit(cibleId: 'x', mecanismes: {
        TypeConflitAssociation.memeFamilleRavageurs,
        TypeConflitAssociation.competitionAzote,
      });
      expect(c.mecanismes, hasLength(2));
    });

    test('famillesDe regroupe les mécanismes par famille', () {
      // brouillage + répulsion partagent la famille Protection → une famille.
      expect(
        famillesDe({
          TypeBeneficeAssociation.brouillageOlfactif,
          TypeBeneficeAssociation.repulsionRavageur,
        }),
        {FamilleEffetAssociation.protectionRavageurs},
      );
      // fixation (fertilité) + tuteur (gain de place) → deux familles.
      expect(
        famillesDe({
          TypeBeneficeAssociation.fixationAzote,
          TypeBeneficeAssociation.tuteurStructurel,
        }),
        {FamilleEffetAssociation.fertilite, FamilleEffetAssociation.gainDePlace},
      );
    });
  });

  group('AssociationBenefique (ADR-0010)', () {
    test('exposes target, mechanism and localised reason', () {
      final a = AssociationBenefique(
        cibleId: 'LEG-001',
        mecanisme: TypeBeneficeAssociation.fixationAzote,
        raisonI18n: const {'fr': 'Enrichit le sol', 'en': 'Enriches the soil'},
      );
      expect(a.cibleId, 'LEG-001');
      expect(a.mecanisme, TypeBeneficeAssociation.fixationAzote);
      expect(a.aRaison, isTrue);
      expect(a.raison('fr'), 'Enrichit le sol');
      expect(a.raison('en'), 'Enriches the soil');
    });

    test('reason falls back to French for an unknown locale', () {
      final a = AssociationBenefique(
        cibleId: 'x',
        raisonI18n: const {'fr': 'Raison'},
      );
      expect(a.raison('de'), 'Raison');
    });

    test('a bare association has no mechanism nor reason', () {
      final a = AssociationBenefique(cibleId: 'x');
      expect(a.mecanisme, isNull);
      expect(a.aRaison, isFalse);
      expect(a.raison('fr'), isNull);
    });

    test('rejects an empty target id', () {
      expect(() => AssociationBenefique(cibleId: ''),
          throwsA(isA<AssertionError>()));
    });

    test('the reason map is copied defensively', () {
      // Only English, so a French lookup has nothing to fall back to.
      final source = {'en': 'r'};
      final a = AssociationBenefique(cibleId: 'x', raisonI18n: source);
      // Mutating the source after construction must not leak in.
      source['fr'] = 'leak';
      expect(a.raison('fr'), isNull);
    });

    test('value equality covers id, mechanism and reason', () {
      final a = AssociationBenefique(
        cibleId: 'x',
        mecanisme: TypeBeneficeAssociation.couvreSol,
        raisonI18n: const {'fr': 'r'},
      );
      final memeChose = AssociationBenefique(
        cibleId: 'x',
        mecanisme: TypeBeneficeAssociation.couvreSol,
        raisonI18n: const {'fr': 'r'},
      );
      final autreMecanisme = AssociationBenefique(
        cibleId: 'x',
        mecanisme: TypeBeneficeAssociation.briseVent,
        raisonI18n: const {'fr': 'r'},
      );
      expect(a, memeChose);
      expect(a.hashCode, memeChose.hashCode);
      expect(a, isNot(autreMecanisme));
    });
  });

  group('AssociationConflit (ADR-0010)', () {
    test('exposes target, mechanism and reason', () {
      final c = AssociationConflit(
        cibleId: 'LEG-002',
        mecanisme: TypeConflitAssociation.allelopathie,
        raisonI18n: const {'fr': 'Inhibe la croissance'},
      );
      expect(c.cibleId, 'LEG-002');
      expect(c.mecanisme, TypeConflitAssociation.allelopathie);
      expect(c.raison('fr'), 'Inhibe la croissance');
    });

    test('rejects an empty target id', () {
      expect(
          () => AssociationConflit(cibleId: ''), throwsA(isA<AssertionError>()));
    });

    test('value equality covers id, mechanism and reason', () {
      final c = AssociationConflit(
        cibleId: 'x',
        mecanisme: TypeConflitAssociation.competitionAzote,
      );
      final memeChose = AssociationConflit(
        cibleId: 'x',
        mecanisme: TypeConflitAssociation.competitionAzote,
      );
      expect(c, memeChose);
      expect(c.hashCode, memeChose.hashCode);
    });
  });
}
