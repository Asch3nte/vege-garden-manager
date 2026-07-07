import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/sous_type_legume.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/modele_fiche_personnelle.dart';

ModeleFichePersonnelle modele({
  CategoriePlante categorie = CategoriePlante.legume,
  SousTypeLegume? sousType = SousTypeLegume.legumeFruit,
  Set<UsagePlante>? usages,
  Set<QualiteSol>? qualitesSol,
  double phMin = 6,
  double phMax = 7,
  int espacementCm = 40,
  int dureeMin = 60,
  int dureeMax = 90,
  int? difficulte,
}) =>
    ModeleFichePersonnelle(
      idFiche: 'perso_tomate',
      categorie: categorie,
      sousType: sousType,
      usages: usages ?? {UsagePlante.alimentaire},
      nomScientifique: 'Solanum lycopersicum',
      familleBotanique: 'solanaceae',
      nomCommunFr: 'Tomate de mémé',
      ensoleillement: NiveauSoleil.pleinSoleil,
      arrosage: BesoinEau.modere,
      qualitesSol: qualitesSol ?? {QualiteSol.riche, QualiteSol.bienDraine},
      phMin: phMin,
      phMax: phMax,
      espacementCm: espacementCm,
      dureeAvantRecolteJoursMin: dureeMin,
      dureeAvantRecolteJoursMax: dureeMax,
      difficulte: difficulte,
    );

void main() {
  test('builds a valid model and exposes immutable sets', () {
    final m = modele();
    expect(m.idFiche, 'perso_tomate');
    expect(m.categorie, CategoriePlante.legume);
    expect(m.sousType, SousTypeLegume.legumeFruit);
    expect(() => m.usages.add(UsagePlante.mellifere), throwsUnsupportedError);
    expect(() => m.qualitesSol.add(QualiteSol.sec), throwsUnsupportedError);
  });

  test('drops sousType when the categorie is not a legume', () {
    final m = modele(categorie: CategoriePlante.fleur);
    expect(m.sousType, isNull);
  });

  test('copyWith replaces only the given fields', () {
    final m = modele().copyWith(nomCommunFr: 'Tomate cerise', phMax: 7.5);
    expect(m.nomCommunFr, 'Tomate cerise');
    expect(m.phMax, 7.5);
    expect(m.phMin, 6); // unchanged
    expect(m.nomScientifique, 'Solanum lycopersicum'); // unchanged
  });

  group('invariants', () {
    test('rejects an empty required name', () {
      expect(() => modele().copyWith(nomCommunFr: ''),
          throwsA(isA<AssertionError>()));
    });
    test('rejects an out-of-range pH', () {
      expect(() => modele(phMax: 15), throwsA(isA<AssertionError>()));
    });
    test('rejects phMin > phMax', () {
      expect(() => modele(phMin: 8, phMax: 6),
          throwsA(isA<AssertionError>()));
    });
    test('rejects an empty usages set', () {
      expect(() => modele(usages: {}), throwsA(isA<AssertionError>()));
    });
    test('rejects dureeMin > dureeMax', () {
      expect(() => modele(dureeMin: 90, dureeMax: 60),
          throwsA(isA<AssertionError>()));
    });
    test('rejects a non-positive espacement', () {
      expect(() => modele(espacementCm: 0), throwsA(isA<AssertionError>()));
    });
    test('rejects difficulte outside 1..3', () {
      expect(() => modele(difficulte: 4), throwsA(isA<AssertionError>()));
    });
  });
}
