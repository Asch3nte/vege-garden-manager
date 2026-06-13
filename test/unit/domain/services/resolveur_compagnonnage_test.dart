import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/services/resolveur_compagnonnage.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';

/// Builds a minimal species sheet [id], declaring [benefiques] as good
/// companions and [negatives] as to-avoid (one-directional, as the source data
/// usually is).
FichePlante uneFiche(
  String id, {
  Set<String> benefiques = const {},
  Set<String> negatives = const {},
}) =>
    FichePlante(
      id: id,
      nomScientifique: '$id sp',
      familleBotanique: 'Test',
      categorie: CategoriePlante.legume,
      usages: const {UsagePlante.alimentaire},
      nomsLocalises: {'fr': id},
      besoins: BesoinsCulture(
        eau: BesoinEau.modere,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: 40,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 80,
      associationsBenefiques: benefiques,
      associationsNegatives: negatives,
    );

void main() {
  const resolveur = ResolveurCompagnonnage();

  group('relationEntre — bidirectionnel', () {
    test('good when only the first declares it', () {
      final a = uneFiche('A', benefiques: {'B'});
      final b = uneFiche('B');
      expect(resolveur.relationEntre(a, b), TypeCompagnonnage.bon);
      // Symmetric: the relation holds whichever way it is asked.
      expect(resolveur.relationEntre(b, a), TypeCompagnonnage.bon);
    });

    test('good when only the second declares it', () {
      final a = uneFiche('A');
      final b = uneFiche('B', benefiques: {'A'});
      expect(resolveur.relationEntre(a, b), TypeCompagnonnage.bon);
      expect(resolveur.relationEntre(b, a), TypeCompagnonnage.bon);
    });

    test('to-avoid when only one declares the conflict', () {
      final a = uneFiche('A', negatives: {'B'});
      final b = uneFiche('B');
      expect(resolveur.relationEntre(a, b), TypeCompagnonnage.aEviter);
      expect(resolveur.relationEntre(b, a), TypeCompagnonnage.aEviter);
    });
  });

  group('relationEntre — précédence et cas neutres', () {
    test('good wins over to-avoid when a pair declares both ways', () {
      final a = uneFiche('A', benefiques: {'B'});
      final b = uneFiche('B', negatives: {'A'});
      expect(resolveur.relationEntre(a, b), TypeCompagnonnage.bon);
      expect(resolveur.relationEntre(b, a), TypeCompagnonnage.bon);
    });

    test('none when neither declares anything', () {
      final a = uneFiche('A');
      final b = uneFiche('B');
      expect(resolveur.relationEntre(a, b), TypeCompagnonnage.aucune);
    });

    test('a sheet has no relationship with itself', () {
      final a = uneFiche('A', benefiques: {'A'}, negatives: {'A'});
      expect(resolveur.relationEntre(a, a), TypeCompagnonnage.aucune);
    });
  });

  group('resoudre — split, exclusion de soi, comptage', () {
    test('splits the catalogue and excludes the sheet itself', () {
      final tomate = uneFiche('tomate', benefiques: {'basilic'});
      final basilic = uneFiche('basilic');
      final pommeDeTerre = uneFiche('pdt', negatives: {'tomate'});
      final carotte = uneFiche('carotte');
      final catalogue = [tomate, basilic, pommeDeTerre, carotte];

      final res = resolveur.resoudre(tomate, catalogue);

      expect(res.bons.map((f) => f.id), ['basilic']);
      expect(res.aEviter.map((f) => f.id), ['pdt']);
      expect(res.nbBons, 1);
      expect(res.nbAEviter, 1);
      // Neither list contains the sheet itself.
      expect(res.bons, isNot(contains(tomate)));
      expect(res.aEviter, isNot(contains(tomate)));
    });

    test('counts match between two sheets of the same pair (alignment)', () {
      // The whole point of ADR-0008: the count seen from either sheet is the
      // same relationship, so the Réseau and the detail sheet agree.
      final a = uneFiche('A', benefiques: {'B'});
      final b = uneFiche('B');
      final catalogue = [a, b];
      expect(resolveur.resoudre(a, catalogue).nbBons, 1);
      expect(resolveur.resoudre(b, catalogue).nbBons, 1);
    });

    test('result lists are immutable', () {
      final res = resolveur.resoudre(uneFiche('A'), [uneFiche('B')]);
      expect(() => res.bons.add(uneFiche('X')), throwsUnsupportedError);
      expect(() => res.aEviter.add(uneFiche('X')), throwsUnsupportedError);
    });
  });
}
