import 'package:riverpod/riverpod.dart';

import '../../domain/entities/famille_botanique.dart';
import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/categorie_plante.dart';
import '../../domain/enums/groupe_cultural.dart';
import '../../domain/enums/niveau_besoin.dart';
import '../../domain/value_objects/precedent_cultural.dart';
import 'resultat_rotation.dart';

/// Pure engine that evaluates **crop-rotation suitability** of a candidate plant
/// on a plot (rotation avancée, Lot 3). It reconciles three signals into one
/// explainable [ResultatRotation]:
///
/// 1. **Family return delay** — the candidate's own family must not have grown
///    here within its `delai_retour_annees` (the existing hard rule).
/// 2. **Declared cultural precedents** — `precedents_favorables` /
///    `precedents_defavorables` matched against what grew here *recently*
///    ([fenetrePrecedentDefautAnnees]). A functional-group precedent resolves
///    against traits, not a family: [GroupeCultural.legumineuses] matches any
///    nitrogen fixer (`fixe_azote`) or a Fabaceae; [GroupeCultural.engraisVerts]
///    matches any [CategoriePlante.engraisVert].
/// 3. **Nitrogen dynamics** — a nitrogen-hungry candidate (`besoin_azote:
///    eleve`) that follows a fixer gets a favorable signal even when the sheet
///    declares no precedent.
///
/// Unfavorable signals dominate favorable ones (rotation is a safety rule).
///
/// Stateless and repository-free: the caller resolves the plot's plantation
/// history into [CulturePrecedente]s (mother sheets + reference dates). This
/// mirrors [EvaluateurRecommandations]/[MoteurDerivationAssociations]. It does
/// **not** replace [RecommanderPlantes]' hard rotation filter; it powers the
/// dedicated rotation screen with a richer, explainable read.
class EvaluationRotation {
  const EvaluationRotation();

  /// Return delay (years) assumed when a sheet states none.
  static const int delaiRetourDefautAnnees = 3;

  /// Look-back window (years) for "what grew here recently" when matching
  /// declared precedents and nitrogen dynamics. The family-conflict rule uses
  /// the candidate's own (usually longer) return delay instead.
  static const int fenetrePrecedentDefautAnnees = 2;

  /// Evaluates [candidate] against the plot's [historique] at [date].
  ///
  /// [rotationApplicable] is `false` for renewable-soil containers (fresh
  /// potting soil resets the rotation clock) — the verdict is then neutral.
  ResultatRotation evaluer({
    required FichePlante candidate,
    required List<CulturePrecedente> historique,
    required DateTime date,
    bool rotationApplicable = true,
    int delaiRetourDefaut = delaiRetourDefautAnnees,
    int fenetrePrecedentAnnees = fenetrePrecedentDefautAnnees,
  }) {
    if (!rotationApplicable || historique.isEmpty) return ResultatRotation.neutre;

    final raisons = <RaisonRotation>[];
    final familleCandidate = _famille(candidate);

    // 1. Family return-delay conflict — over the candidate's own delay window.
    final delai = candidate.delaiRetourAnnees ?? delaiRetourDefaut;
    final seuilFamille = _recul(date, delai);
    for (final c in historique) {
      if (_famille(c.fiche) == familleCandidate &&
          c.dateReference.isAfter(seuilFamille)) {
        raisons.add(RaisonRotation.conflitFamille(
          familleSlug: familleCandidate,
          cultureId: c.fiche.id,
          anneesDepuis: _anneesDepuis(c.dateReference, date),
          delaiRequis: delai,
        ));
      }
    }

    // Precedents & nitrogen only consider recent history.
    final seuilPrecedent = _recul(date, fenetrePrecedentAnnees);
    final recents =
        historique.where((c) => c.dateReference.isAfter(seuilPrecedent));

    // 2. Declared unfavorable precedents present in recent history.
    for (final c in recents) {
      for (final p in candidate.precedentsDefavorables) {
        if (_correspond(p, c.fiche)) {
          raisons.add(RaisonRotation.precedentDefavorable(
            precedent: p,
            cultureId: c.fiche.id,
            anneesDepuis: _anneesDepuis(c.dateReference, date),
          ));
        }
      }
    }

    // 3. Declared favorable precedents present.
    for (final c in recents) {
      for (final p in candidate.precedentsFavorables) {
        if (_correspond(p, c.fiche)) {
          raisons.add(RaisonRotation.precedentFavorable(
            precedent: p,
            cultureId: c.fiche.id,
            anneesDepuis: _anneesDepuis(c.dateReference, date),
          ));
        }
      }
    }

    // 4. Derived nitrogen bonus: a hungry candidate after a fixer — but not when
    //    a favorable precedent already credits that same past culture.
    if (candidate.besoinAzote == NiveauBesoin.eleve) {
      for (final c in recents) {
        if (c.fiche.fixeAzote && !_dejaCreditee(raisons, c.fiche.id)) {
          raisons.add(RaisonRotation.azoteApresLegumineuse(
            cultureId: c.fiche.id,
            anneesDepuis: _anneesDepuis(c.dateReference, date),
          ));
        }
      }
    }

    return ResultatRotation(_verdict(raisons), raisons);
  }

  /// Whether [fiche] satisfies the precedent [p]: a family precedent matches by
  /// normalized family; a group precedent matches by trait/category.
  bool _correspond(PrecedentCultural p, FichePlante fiche) {
    if (p.estFamille) return _famille(fiche) == p.familleSlug;
    return switch (p.groupe!) {
      GroupeCultural.legumineuses =>
        fiche.fixeAzote || _famille(fiche) == 'fabaceae',
      GroupeCultural.engraisVerts =>
        fiche.categorie == CategoriePlante.engraisVert,
    };
  }

  /// Unfavorable dominates favorable; no reason ⇒ neutral.
  VerdictRotation _verdict(List<RaisonRotation> raisons) {
    if (raisons.any((r) => !r.favorable)) return VerdictRotation.defavorable;
    if (raisons.any((r) => r.favorable)) return VerdictRotation.favorable;
    return VerdictRotation.neutre;
  }

  /// Whether a favorable-precedent reason already credits culture [cultureId]
  /// (avoids double-counting the nitrogen bonus with a declared legume precedent).
  bool _dejaCreditee(List<RaisonRotation> raisons, String cultureId) =>
      raisons.any((r) =>
          r.motif == MotifRotation.precedentFavorable &&
          r.cultureId == cultureId);

  /// Normalized botanical family key: `rotation.famille` when present, else the
  /// declared `famille_botanique` (both folded to a slug so `Solanaceae` and
  /// `solanaceae` compare equal).
  String _famille(FichePlante f) =>
      FamilleBotanique.normaliserCle(f.rotationFamille ?? f.familleBotanique);

  DateTime _recul(DateTime date, int annees) =>
      DateTime(date.year - annees, date.month, date.day);

  int _anneesDepuis(DateTime passe, DateTime maintenant) =>
      maintenant.difference(passe).inDays ~/ 365;
}

/// DI provider for the (stateless) [EvaluationRotation].
final evaluationRotationProvider = Provider<EvaluationRotation>(
  (ref) => const EvaluationRotation(),
);
