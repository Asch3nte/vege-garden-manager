import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/derivation_sol.dart';
import 'package:pot_a_gerer/application/engine/evaluateur_recommandations.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/raison_reco.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/recommandation_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

void main() {
  group('DerivationSol.qualitesDe', () {
    const sol = DerivationSol();

    test('texture maps to base qualities', () {
      expect(sol.qualitesDe(TextureSol.argileux, const {}),
          containsAll([QualiteSol.lourd, QualiteSol.riche, QualiteSol.malDraine]));
      expect(sol.qualitesDe(TextureSol.sableux, const {}),
          containsAll([QualiteSol.leger, QualiteSol.bienDraine, QualiteSol.sec]));
    });

    test('enriching/cooling techniques add qualities', () {
      final q = sol.qualitesDe(
          TextureSol.sableux, {TechniqueSol.compostEnTrou, TechniqueSol.paillage});
      expect(q, contains(QualiteSol.riche)); // compost
      expect(q, contains(QualiteSol.frais)); // mulch
    });

    test('unknown texture without technique yields nothing', () {
      expect(sol.qualitesDe(null, const {}), isEmpty);
      expect(sol.qualitesDe(null, {TechniqueSol.compostEnTrou}),
          {QualiteSol.riche});
    });
  });

  group('EvaluateurRecommandations', () {
    const eval = EvaluateurRecommandations();
    final juin = DateTime.utc(2026, 6, 15);

    FichePlante fiche({
      String id = 'tomate',
      NiveauSoleil soleil = NiveauSoleil.pleinSoleil,
      Set<QualiteSol> qualitesSol = const {},
      int espacementCm = 60,
      Periode? plantation = const Periode(5, 6), // plantable in June
      Set<String> benefiques = const {},
      Set<String> negatives = const {},
    }) =>
        FichePlante(
          id: id,
          nomScientifique: 'X y',
          familleBotanique: 'Fam',
          categorie: CategoriePlante.legume,
          usages: const {UsagePlante.alimentaire},
          nomsLocalises: const {'fr': 'X'},
          besoins: BesoinsCulture(
            eau: BesoinEau.modere,
            soleil: soleil,
            phMin: 6,
            phMax: 7,
            qualitesSol: qualitesSol,
          ),
          espacementCm: espacementCm,
          dureeAvantRecolteJoursMin: 70,
          dureeAvantRecolteJoursMax: 90,
          periodes: {
            Hemisphere.nord: {
              TypeClimat.oceanique: PeriodesCulture(plantation: plantation),
            },
          },
          associationsBenefiques: benefiques,
          associationsNegatives: negatives,
        );

    RecommandationPlante? evaluer(
      FichePlante f, {
      NiveauSoleil exposition = NiveauSoleil.pleinSoleil,
      Set<QualiteSol> qualitesSol = const {},
      Surface? surfaceLibre,
      Set<String> actifs = const {},
      bool rotationConflit = false,
      bool rotationVerifiee = true,
      Hemisphere? hemisphere = Hemisphere.nord,
      TypeClimat? climat = TypeClimat.oceanique,
    }) =>
        eval.evaluer(
          candidate: f,
          date: juin,
          hemisphere: hemisphere,
          climat: climat,
          exposition: exposition,
          qualitesSol: qualitesSol,
          surfaceLibre: surfaceLibre ?? Surface.enMetresCarres(4),
          planteIdsActifs: actifs,
          rotationConflit: rotationConflit,
          rotationVerifiee: rotationVerifiee,
        );

    test('excludes a plant not plantable this season', () {
      final r = evaluer(fiche(plantation: const Periode(1, 2))); // Jan-Feb only
      expect(r, isNull);
    });

    test('excludes when the parcelle has no room (spacing)', () {
      // 100 cm spacing -> 1 m² per plant; only 0.5 m² free.
      final r = evaluer(fiche(espacementCm: 100),
          surfaceLibre: Surface.enMetresCarres(0.5));
      expect(r, isNull);
    });

    test('excludes on a rotation conflict', () {
      expect(evaluer(fiche(), rotationConflit: true), isNull);
    });

    test('excludes on a hard companion conflict', () {
      final r = evaluer(fiche(negatives: {'fenouil'}), actifs: {'fenouil'});
      expect(r, isNull);
    });

    test('recommends with the right reasons when everything fits', () {
      final r = evaluer(
        fiche(
          soleil: NiveauSoleil.pleinSoleil,
          qualitesSol: {QualiteSol.riche},
          benefiques: {'basilic'},
        ),
        exposition: NiveauSoleil.pleinSoleil,
        qualitesSol: {QualiteSol.riche, QualiteSol.frais},
        actifs: {'basilic'},
      );
      expect(r, isNotNull);
      expect(
          r!.raisons,
          containsAll([
            RaisonReco.plantableMaintenant,
            RaisonReco.expositionAdaptee,
            RaisonReco.solAdapte,
            RaisonReco.bonneAssociation,
            RaisonReco.rotationFavorable,
          ]));
      expect(r.score, greaterThan(0.8));
    });

    test('a sun mismatch lowers the score and drops the reason', () {
      final shade = evaluer(
        fiche(soleil: NiveauSoleil.ombre),
        exposition: NiveauSoleil.pleinSoleil, // 2 levels off
      );
      expect(shade, isNotNull);
      expect(shade!.raisons, isNot(contains(RaisonReco.expositionAdaptee)));
      final sun = evaluer(fiche(soleil: NiveauSoleil.pleinSoleil));
      expect(sun!.score, greaterThan(shade.score));
    });

    test('skips the season filter when climate is unknown', () {
      final r = evaluer(
        fiche(plantation: const Periode(1, 2)), // not plantable in June...
        hemisphere: null,
        climat: null, // ...but climate unknown -> filter skipped
      );
      expect(r, isNotNull);
      expect(r!.raisons, isNot(contains(RaisonReco.plantableMaintenant)));
    });

    test('no rotationFavorable reason when rotation was not checked', () {
      final r = evaluer(fiche(), rotationVerifiee: false);
      expect(r!.raisons, isNot(contains(RaisonReco.rotationFavorable)));
    });
  });
}
