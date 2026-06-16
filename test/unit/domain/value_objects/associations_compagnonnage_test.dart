import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/type_benefice_association.dart';
import 'package:pot_a_gerer/domain/enums/type_conflit_association.dart';
import 'package:pot_a_gerer/domain/value_objects/association_benefique.dart';
import 'package:pot_a_gerer/domain/value_objects/association_conflit.dart';

void main() {
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
