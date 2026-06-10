import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/derivation_sol.dart';
import 'package:pot_a_gerer/application/engine/evaluateur_recommandations.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/niveau_experience.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/qualite_sol.dart';
import 'package:pot_a_gerer/domain/enums/raison_reco.dart';
import 'package:pot_a_gerer/domain/enums/technique_sol.dart';
import 'package:pot_a_gerer/domain/enums/texture_sol.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
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

    // --- §A Rusticité -------------------------------------------------------
    group('hardiness filter §A', () {
      FichePlante ficheRusticite(ZoneRusticite zoneMin) => FichePlante(
            id: 'citrus',
            nomScientifique: 'Citrus sp',
            familleBotanique: 'Rutaceae',
            categorie: CategoriePlante.fruit,
            usages: const {UsagePlante.alimentaire},
            nomsLocalises: const {'fr': 'Citrus'},
            besoins: BesoinsCulture(
                eau: BesoinEau.modere,
                soleil: NiveauSoleil.pleinSoleil,
                phMin: 5,
                phMax: 7),
            espacementCm: 300,
            dureeAvantRecolteJoursMin: 180,
            dureeAvantRecolteJoursMax: 365,
            rusticiteMin: zoneMin,
          );

      test('excludes plant when potager zone is colder than rusticiteMin', () {
        // Plant needs zone9 (no frost), potager is zone7 (frost).
        final r = eval.evaluer(
          candidate: ficheRusticite(ZoneRusticite.zone9),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(20),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          zoneRusticite: ZoneRusticite.zone7,
        );
        expect(r, isNull);
      });

      test('accepts plant when potager zone meets rusticiteMin', () {
        // Plant needs zone7, potager is zone8 (warmer) → OK.
        final r = eval.evaluer(
          candidate: ficheRusticite(ZoneRusticite.zone7),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(20),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          zoneRusticite: ZoneRusticite.zone8,
        );
        expect(r, isNotNull);
      });

      test('skips hardiness filter when zoneRusticite is null', () {
        // No zone provided → filter inactive, plant still recommended.
        final r = eval.evaluer(
          candidate: ficheRusticite(ZoneRusticite.zone11),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(20),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
        );
        expect(r, isNotNull);
      });
    });

    // --- §C Difficulté ------------------------------------------------------
    group('difficulty filter §C', () {
      FichePlante ficheD(int d) => FichePlante(
            id: 'x',
            nomScientifique: 'X sp',
            familleBotanique: 'Fam',
            categorie: CategoriePlante.legume,
            usages: const {UsagePlante.alimentaire},
            nomsLocalises: const {'fr': 'X'},
            besoins: BesoinsCulture(
                eau: BesoinEau.faible,
                soleil: NiveauSoleil.pleinSoleil,
                phMin: 6,
                phMax: 7),
            espacementCm: 30,
            dureeAvantRecolteJoursMin: 30,
            dureeAvantRecolteJoursMax: 60,
            difficulte: d,
          );

      test('excludes level-3 plant for a debutant', () {
        final r = eval.evaluer(
          candidate: ficheD(3),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          niveauExperience: NiveauExperience.debutant,
        );
        expect(r, isNull);
      });

      test('accepts level-2 plant for an intermediaire', () {
        final r = eval.evaluer(
          candidate: ficheD(2),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          niveauExperience: NiveauExperience.intermediaire,
        );
        expect(r, isNotNull);
        expect(r!.raisons, contains(RaisonReco.niveauAdapte));
      });

      test('skips difficulty filter when niveauExperience is null', () {
        final r = eval.evaluer(
          candidate: ficheD(3),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
        );
        expect(r, isNotNull);
      });
    });

    // --- §D Contenant -------------------------------------------------------
    group('container filter §D', () {
      FichePlante ficheContenant({required bool compatible}) => FichePlante(
            id: 'courge',
            nomScientifique: 'Cucurbita sp',
            familleBotanique: 'Cucurbitaceae',
            categorie: CategoriePlante.legume,
            usages: const {UsagePlante.alimentaire},
            nomsLocalises: const {'fr': 'Courge'},
            besoins: BesoinsCulture(
                eau: BesoinEau.eleve,
                soleil: NiveauSoleil.pleinSoleil,
                phMin: 6,
                phMax: 7),
            espacementCm: 100,
            dureeAvantRecolteJoursMin: 90,
            dureeAvantRecolteJoursMax: 120,
            compatibleHorsSol: compatible,
          );

      test('excludes incompatible plant for a pot parcelle', () {
        final r = eval.evaluer(
          candidate: ficheContenant(compatible: false),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          typeParcelle: TypeParcelle.pot,
        );
        expect(r, isNull);
      });

      test('accepts compatible plant for a jardiniere', () {
        final r = eval.evaluer(
          candidate: ficheContenant(compatible: true),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          typeParcelle: TypeParcelle.jardiniere,
        );
        expect(r, isNotNull);
      });

      test('accepts any plant for pleine-terre regardless of compatibleHorsSol', () {
        final r = eval.evaluer(
          candidate: ficheContenant(compatible: false),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          typeParcelle: TypeParcelle.pleineTerre,
        );
        expect(r, isNotNull);
      });
    });

    // --- §I soleilMin -------------------------------------------------------
    group('sun tolerance range §I', () {
      FichePlante ficheTomate() => FichePlante(
            id: 'tomate_sol',
            nomScientifique: 'Solanum lycopersicum',
            familleBotanique: 'Solanaceae',
            categorie: CategoriePlante.legume,
            usages: const {UsagePlante.alimentaire},
            nomsLocalises: const {'fr': 'Tomate'},
            besoins: BesoinsCulture(
              eau: BesoinEau.eleve,
              soleil: NiveauSoleil.pleinSoleil,
              soleilMin: NiveauSoleil.miOmbre, // tolerates mi-ombre
              phMin: 6,
              phMax: 7,
            ),
            espacementCm: 60,
            dureeAvantRecolteJoursMin: 70,
            dureeAvantRecolteJoursMax: 90,
          );

      test('gives 1.0 at preferred level', () {
        final r = eval.evaluer(
          candidate: ficheTomate(),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.pleinSoleil,
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          hemisphere: null,
          climat: null,
        );
        // score = 0.4*1.0 + 0.4*1.0 + 0.2*0.5 = 0.9
        expect(r, isNotNull);
        expect(r!.raisons, contains(RaisonReco.expositionAdaptee));
      });

      test('gives 0.5 within tolerance range', () {
        final r = eval.evaluer(
          candidate: ficheTomate(),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.miOmbre, // within [pleinSoleil..miOmbre]
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          hemisphere: null,
          climat: null,
        );
        // score exposition = 0.5 (within tolerance, not perfect)
        expect(r, isNotNull);
        expect(r!.raisons, contains(RaisonReco.expositionAdaptee)); // >= 0.5
      });

      test('gives 0.0 when below minimum tolerance', () {
        final r = eval.evaluer(
          candidate: ficheTomate(),
          date: DateTime.utc(2026, 6, 15),
          exposition: NiveauSoleil.ombre, // below soleilMin (miOmbre)
          qualitesSol: const {},
          surfaceLibre: Surface.enMetresCarres(4),
          planteIdsActifs: const {},
          rotationConflit: false,
          rotationVerifiee: false,
          hemisphere: null,
          climat: null,
        );
        expect(r, isNotNull);
        expect(r!.raisons, isNot(contains(RaisonReco.expositionAdaptee)));
      });
    });

    // --- §E Culture verticale -----------------------------------------------
    test('adds cultureVerticaleCompatible reason when plant and parcelle match', () {
      final plante = FichePlante(
        id: 'haricot_grimpant',
        nomScientifique: 'Phaseolus vulgaris',
        familleBotanique: 'Fabaceae',
        categorie: CategoriePlante.legume,
        usages: const {UsagePlante.alimentaire},
        nomsLocalises: const {'fr': 'Haricot grimpant'},
        besoins: BesoinsCulture(
            eau: BesoinEau.modere,
            soleil: NiveauSoleil.pleinSoleil,
            phMin: 6,
            phMax: 7),
        espacementCm: 20,
        dureeAvantRecolteJoursMin: 60,
        dureeAvantRecolteJoursMax: 80,
        cultureVerticale: true,
      );

      final avecTreillis = eval.evaluer(
        candidate: plante,
        date: DateTime.utc(2026, 6, 15),
        exposition: NiveauSoleil.pleinSoleil,
        qualitesSol: const {},
        surfaceLibre: Surface.enMetresCarres(4),
        planteIdsActifs: const {},
        rotationConflit: false,
        rotationVerifiee: false,
        cultureVerticaleDisponible: true,
      );
      expect(avecTreillis!.raisons, contains(RaisonReco.cultureVerticaleCompatible));

      final sansTreillis = eval.evaluer(
        candidate: plante,
        date: DateTime.utc(2026, 6, 15),
        exposition: NiveauSoleil.pleinSoleil,
        qualitesSol: const {},
        surfaceLibre: Surface.enMetresCarres(4),
        planteIdsActifs: const {},
        rotationConflit: false,
        rotationVerifiee: false,
      );
      expect(sansTreillis!.raisons,
          isNot(contains(RaisonReco.cultureVerticaleCompatible)));
    });
  });
}
