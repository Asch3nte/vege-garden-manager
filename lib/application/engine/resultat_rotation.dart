import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/groupe_cultural.dart';
import '../../domain/value_objects/precedent_cultural.dart';

/// One past culture on a plot, resolved to the **mother** sheet of what grew
/// there and the date it should be measured from (its end date, else its
/// planting date). Assembled by the caller from the plot's plantation history
/// so that [EvaluationRotation] stays pure (no repositories).
class CulturePrecedente {
  /// Mother sheet of the plant that grew (ADR-0005: varieties resolve to it).
  final FichePlante fiche;

  /// Reference date for recency: the culture's real end date when finished,
  /// otherwise its planting date.
  final DateTime dateReference;

  const CulturePrecedente({required this.fiche, required this.dateReference});
}

/// Overall crop-rotation verdict for placing a candidate on a plot.
enum VerdictRotation {
  /// At least one favorable signal and no unfavorable one.
  favorable,

  /// At least one unfavorable signal (it dominates: rotation is a safety rule).
  defavorable,

  /// No decisive signal either way (or rotation does not apply here).
  neutre,
}

/// Why a rotation verdict leans the way it does — the explainable building
/// block behind [ResultatRotation].
enum MotifRotation {
  /// The candidate's own botanical family grew here within its return delay.
  conflitFamille,

  /// A declared **unfavorable** cultural precedent is present in recent history.
  precedentDefavorable,

  /// A declared **favorable** cultural precedent is present in recent history.
  precedentFavorable,

  /// A nitrogen-hungry candidate follows a nitrogen fixer (derived from traits,
  /// even when the sheet declares no precedent).
  azoteApresLegumineuse,
}

/// A single, explainable reason contributing to a [ResultatRotation]. Carries
/// the real values behind the motive so the UI (Lot 4) can phrase it precisely
/// (which family/group, which past culture, how long ago, the required delay).
class RaisonRotation {
  /// What kind of signal this is.
  final MotifRotation motif;

  /// Whether the signal argues *for* placing the candidate here.
  final bool favorable;

  /// Family slug involved (family conflict, or a family precedent), else `null`.
  final String? familleConcernee;

  /// Functional group involved (a group precedent), else `null`.
  final GroupeCultural? groupeConcerne;

  /// Mother id of the past culture that triggered the reason.
  final String cultureId;

  /// Whole years elapsed since that culture's reference date.
  final int anneesDepuis;

  /// Required family return delay (years) — only for [MotifRotation.conflitFamille].
  final int? delaiRequis;

  const RaisonRotation._({
    required this.motif,
    required this.favorable,
    required this.cultureId,
    required this.anneesDepuis,
    this.familleConcernee,
    this.groupeConcerne,
    this.delaiRequis,
  });

  /// The candidate's family grew here too recently (unfavorable).
  RaisonRotation.conflitFamille({
    required String familleSlug,
    required String cultureId,
    required int anneesDepuis,
    required int delaiRequis,
  }) : this._(
          motif: MotifRotation.conflitFamille,
          favorable: false,
          familleConcernee: familleSlug,
          cultureId: cultureId,
          anneesDepuis: anneesDepuis,
          delaiRequis: delaiRequis,
        );

  /// A recent culture matches a declared unfavorable precedent.
  RaisonRotation.precedentDefavorable({
    required PrecedentCultural precedent,
    required String cultureId,
    required int anneesDepuis,
  }) : this._(
          motif: MotifRotation.precedentDefavorable,
          favorable: false,
          familleConcernee: precedent.familleSlug,
          groupeConcerne: precedent.groupe,
          cultureId: cultureId,
          anneesDepuis: anneesDepuis,
        );

  /// A recent culture matches a declared favorable precedent.
  RaisonRotation.precedentFavorable({
    required PrecedentCultural precedent,
    required String cultureId,
    required int anneesDepuis,
  }) : this._(
          motif: MotifRotation.precedentFavorable,
          favorable: true,
          familleConcernee: precedent.familleSlug,
          groupeConcerne: precedent.groupe,
          cultureId: cultureId,
          anneesDepuis: anneesDepuis,
        );

  /// A nitrogen-hungry candidate follows a nitrogen fixer (derived).
  RaisonRotation.azoteApresLegumineuse({
    required String cultureId,
    required int anneesDepuis,
  }) : this._(
          motif: MotifRotation.azoteApresLegumineuse,
          favorable: true,
          cultureId: cultureId,
          anneesDepuis: anneesDepuis,
        );
}

/// The outcome of evaluating crop rotation for a candidate on a plot: an
/// overall [verdict] and the ordered [raisons] that justify it (unfavorable
/// reasons first, then favorable ones).
class ResultatRotation {
  /// Overall verdict.
  final VerdictRotation verdict;

  /// Explainable reasons behind [verdict] (unmodifiable, possibly empty).
  final List<RaisonRotation> raisons;

  ResultatRotation(this.verdict, List<RaisonRotation> raisons)
      : raisons = List.unmodifiable(raisons);

  /// A neutral result with no reasons (rotation not applicable, or no history).
  static final ResultatRotation neutre =
      ResultatRotation(VerdictRotation.neutre, const []);
}
