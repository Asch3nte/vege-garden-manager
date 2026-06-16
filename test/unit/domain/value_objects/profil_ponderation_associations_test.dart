import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/poids_association.dart';
import 'package:pot_a_gerer/domain/value_objects/profil_ponderation_associations.dart';

void main() {
  group('ProfilPonderationAssociations (ADR-0011)', () {
    test('the default profile is neutral (all normal)', () {
      final p = ProfilPonderationAssociations.defaut();
      expect(p.estDefaut, isTrue);
      for (final f in FamilleEffetAssociation.values) {
        expect(p.poids(f), PoidsAssociation.normal);
        expect(p.multiplicateur(f), 1.0);
      }
    });

    test('a missing family reads as normal (always total)', () {
      final p = ProfilPonderationAssociations(const {});
      expect(p.poids(FamilleEffetAssociation.fertilite), PoidsAssociation.normal);
      expect(p.estDefaut, isTrue);
    });

    test('avec overrides one family without touching the others', () {
      final p = ProfilPonderationAssociations.defaut()
          .avec(FamilleEffetAssociation.protectionRavageurs, PoidsAssociation.ignore);
      expect(p.poids(FamilleEffetAssociation.protectionRavageurs),
          PoidsAssociation.ignore);
      expect(p.multiplicateur(FamilleEffetAssociation.protectionRavageurs), 0.0);
      expect(p.poids(FamilleEffetAssociation.gainDePlace), PoidsAssociation.normal);
      expect(p.estDefaut, isFalse);
    });

    test('the source map is copied (defensive) and unmodifiable', () {
      final source = {FamilleEffetAssociation.fertilite: PoidsAssociation.fort};
      final p = ProfilPonderationAssociations(source);
      source[FamilleEffetAssociation.fertilite] = PoidsAssociation.ignore;
      expect(p.poids(FamilleEffetAssociation.fertilite), PoidsAssociation.fort);
    });

    test('value equality is by per-family weight', () {
      final a = ProfilPonderationAssociations.defaut()
          .avec(FamilleEffetAssociation.gainDePlace, PoidsAssociation.fort);
      final b = ProfilPonderationAssociations(const {
        FamilleEffetAssociation.gainDePlace: PoidsAssociation.fort,
      });
      // b omits the others → they read as normal, like a.
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(ProfilPonderationAssociations.defaut()));
    });

    test('PoidsAssociation multipliers', () {
      expect(PoidsAssociation.ignore.multiplicateur, 0.0);
      expect(PoidsAssociation.faible.multiplicateur, 0.5);
      expect(PoidsAssociation.normal.multiplicateur, 1.0);
      expect(PoidsAssociation.fort.multiplicateur, 1.5);
    });
  });
}
