import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/evaluation_rotation.dart';
import 'package:pot_a_gerer/application/engine/resultat_rotation.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/groupe_cultural.dart';
import 'package:pot_a_gerer/domain/enums/niveau_besoin.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/precedent_cultural.dart';

FichePlante _fiche({
  required String id,
  String famille = 'solanaceae',
  int? delaiRetour,
  CategoriePlante categorie = CategoriePlante.legume,
  bool fixeAzote = false,
  NiveauBesoin? besoinAzote,
  Set<PrecedentCultural>? favorables,
  Set<PrecedentCultural>? defavorables,
}) =>
    FichePlante(
      id: id,
      nomScientifique: 'Genus $id',
      familleBotanique: famille,
      rotationFamille: famille,
      categorie: categorie,
      usages: {UsagePlante.alimentaire},
      nomsLocalises: {'fr': id},
      besoins: BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 7),
      espacementCm: 30,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 80,
      delaiRetourAnnees: delaiRetour,
      fixeAzote: fixeAzote,
      besoinAzote: besoinAzote,
      precedentsFavorables: favorables,
      precedentsDefavorables: defavorables,
    );

void main() {
  const eval = EvaluationRotation();
  final maintenant = DateTime.utc(2026, 6, 15);

  CulturePrecedente passe(FichePlante f, {int ilYADesAnnees = 1}) =>
      CulturePrecedente(
        fiche: f,
        dateReference: DateTime.utc(maintenant.year - ilYADesAnnees, 6, 15),
      );

  group('EvaluationRotation — neutre', () {
    test('no history yields a neutral verdict with no reasons', () {
      final r = eval.evaluer(
        candidate: _fiche(id: 'tomate'),
        historique: const [],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.neutre);
      expect(r.raisons, isEmpty);
    });

    test('rotationApplicable=false (renewable soil) is always neutral', () {
      final r = eval.evaluer(
        candidate: _fiche(id: 'tomate', famille: 'solanaceae', delaiRetour: 4),
        historique: [passe(_fiche(id: 'pdt', famille: 'solanaceae'))],
        date: maintenant,
        rotationApplicable: false,
      );
      expect(r.verdict, VerdictRotation.neutre);
    });
  });

  group('EvaluationRotation — family return delay', () {
    test('same family within the delay is an unfavorable conflict', () {
      final r = eval.evaluer(
        candidate: _fiche(id: 'tomate', famille: 'solanaceae', delaiRetour: 4),
        historique: [passe(_fiche(id: 'pdt', famille: 'solanaceae'))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.defavorable);
      final raison = r.raisons.single;
      expect(raison.motif, MotifRotation.conflitFamille);
      expect(raison.favorable, isFalse);
      expect(raison.familleConcernee, 'solanaceae');
      expect(raison.cultureId, 'pdt');
      expect(raison.delaiRequis, 4);
      expect(raison.anneesDepuis, 1);
    });

    test('same family beyond the delay is not flagged', () {
      final r = eval.evaluer(
        candidate: _fiche(id: 'tomate', famille: 'solanaceae', delaiRetour: 4),
        historique: [
          passe(_fiche(id: 'pdt', famille: 'solanaceae'), ilYADesAnnees: 5),
        ],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.neutre);
    });

    test('family comparison folds capitalization (Solanaceae ≡ solanaceae)', () {
      final r = eval.evaluer(
        candidate: _fiche(id: 'tomate', famille: 'solanaceae', delaiRetour: 4),
        historique: [passe(_fiche(id: 'pdt', famille: 'Solanaceae'))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.defavorable);
    });
  });

  group('EvaluationRotation — declared precedents', () {
    test('an unfavorable family precedent present is defavorable', () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'carotte',
          famille: 'apiaceae',
          defavorables: {PrecedentCultural.famille('solanaceae')},
        ),
        historique: [passe(_fiche(id: 'tomate', famille: 'solanaceae'))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.defavorable);
      final raison = r.raisons.single;
      expect(raison.motif, MotifRotation.precedentDefavorable);
      expect(raison.familleConcernee, 'solanaceae');
      expect(raison.cultureId, 'tomate');
    });

    test('a favorable family precedent present is favorable', () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'tomate',
          famille: 'solanaceae',
          favorables: {PrecedentCultural.famille('fabaceae')},
        ),
        historique: [passe(_fiche(id: 'pois', famille: 'fabaceae'))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.favorable);
      expect(r.raisons.single.motif, MotifRotation.precedentFavorable);
    });

    test('a precedent older than the recency window is ignored', () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'tomate',
          favorables: {PrecedentCultural.famille('fabaceae')},
        ),
        historique: [
          passe(_fiche(id: 'pois', famille: 'fabaceae'), ilYADesAnnees: 3),
        ],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.neutre);
    });
  });

  group('EvaluationRotation — group precedents (trait reconciliation)', () {
    test('legumineuses matches a nitrogen fixer by trait', () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'tomate',
          favorables: {
            const PrecedentCultural.groupe(GroupeCultural.legumineuses),
          },
        ),
        // Not Fabaceae by family, but flagged fixe_azote → still matches.
        historique: [passe(_fiche(id: 'engrais', famille: 'x', fixeAzote: true))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.favorable);
      expect(r.raisons.single.groupeConcerne, GroupeCultural.legumineuses);
    });

    test('legumineuses matches a Fabaceae even without the fixe_azote flag', () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'tomate',
          favorables: {
            const PrecedentCultural.groupe(GroupeCultural.legumineuses),
          },
        ),
        historique: [passe(_fiche(id: 'pois', famille: 'fabaceae'))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.favorable);
    });

    test('engraisVerts matches by category', () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'tomate',
          favorables: {
            const PrecedentCultural.groupe(GroupeCultural.engraisVerts),
          },
        ),
        historique: [
          passe(_fiche(
              id: 'phacelie', famille: 'x', categorie: CategoriePlante.engraisVert)),
        ],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.favorable);
    });
  });

  group('EvaluationRotation — derived nitrogen dynamics', () {
    test('a nitrogen-hungry candidate after a fixer gets a derived bonus', () {
      final r = eval.evaluer(
        candidate: _fiche(
            id: 'tomate', famille: 'solanaceae', besoinAzote: NiveauBesoin.eleve),
        historique: [passe(_fiche(id: 'pois', famille: 'fabaceae', fixeAzote: true))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.favorable);
      expect(r.raisons.single.motif, MotifRotation.azoteApresLegumineuse);
      expect(r.raisons.single.cultureId, 'pois');
    });

    test('a low nitrogen need earns no derived bonus', () {
      final r = eval.evaluer(
        candidate: _fiche(
            id: 'ail', famille: 'amaryllidaceae', besoinAzote: NiveauBesoin.faible),
        historique: [passe(_fiche(id: 'pois', famille: 'fabaceae', fixeAzote: true))],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.neutre);
    });

    test('the nitrogen bonus does not double-count a declared legume precedent',
        () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'tomate',
          famille: 'solanaceae',
          besoinAzote: NiveauBesoin.eleve,
          favorables: {
            const PrecedentCultural.groupe(GroupeCultural.legumineuses),
          },
        ),
        historique: [passe(_fiche(id: 'pois', famille: 'fabaceae', fixeAzote: true))],
        date: maintenant,
      );
      // One favorable reason for that culture, not two.
      expect(r.raisons, hasLength(1));
      expect(r.raisons.single.motif, MotifRotation.precedentFavorable);
      expect(r.verdict, VerdictRotation.favorable);
    });
  });

  group('EvaluationRotation — verdict aggregation', () {
    test('an unfavorable signal dominates a favorable one', () {
      final r = eval.evaluer(
        candidate: _fiche(
          id: 'tomate',
          famille: 'solanaceae',
          delaiRetour: 4,
          besoinAzote: NiveauBesoin.eleve,
        ),
        historique: [
          passe(_fiche(id: 'pdt', famille: 'solanaceae')), // family conflict (−)
          passe(_fiche(id: 'pois', famille: 'fabaceae', fixeAzote: true)), // N (+)
        ],
        date: maintenant,
      );
      expect(r.verdict, VerdictRotation.defavorable);
      expect(r.raisons.map((e) => e.motif),
          containsAll([MotifRotation.conflitFamille, MotifRotation.azoteApresLegumineuse]));
    });

    test('exposed reasons list is unmodifiable', () {
      final r = eval.evaluer(
        candidate: _fiche(id: 'tomate', famille: 'solanaceae', delaiRetour: 4),
        historique: [passe(_fiche(id: 'pdt', famille: 'solanaceae'))],
        date: maintenant,
      );
      expect(() => r.raisons.clear(), throwsUnsupportedError);
    });
  });
}
