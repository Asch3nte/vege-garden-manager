import 'recommandation_plante.dart';

/// Immutable result of a recommendation query for a parcelle: the ranked
/// [recommandations] plus a flag telling whether the seasonal filter could be
/// applied.
///
/// When the user's climate/hemisphere is unknown (position opt-out, no
/// onboarding yet), the season filter is skipped and [saisonNonVerifiee] is
/// `true` — the recommendations still apply the other criteria, but the UI
/// should warn that planting-season suitability was not checked.
///
/// A **result** value object produced by the engine, not persisted.
class ResultatRecommandations {
  final List<RecommandationPlante> _recommandations;
  final bool _saisonNonVerifiee;

  ResultatRecommandations._(this._recommandations, this._saisonNonVerifiee);

  factory ResultatRecommandations({
    required List<RecommandationPlante> recommandations,
    bool saisonNonVerifiee = false,
  }) =>
      ResultatRecommandations._(
        List<RecommandationPlante>.unmodifiable(recommandations),
        saisonNonVerifiee,
      );

  /// Recommendations ordered by descending [RecommandationPlante.score]
  /// (unmodifiable).
  List<RecommandationPlante> get recommandations => _recommandations;

  /// Whether the planting-season filter was skipped (climate unknown).
  bool get saisonNonVerifiee => _saisonNonVerifiee;

  @override
  String toString() => 'ResultatRecommandations(${_recommandations.length}, '
      'saisonNonVerifiee: $_saisonNonVerifiee)';
}
