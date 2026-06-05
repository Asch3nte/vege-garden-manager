import '../enums/raison_reco.dart';

/// Immutable recommendation of one plant for a parcelle: a **result** value
/// object produced by the engine (`EvaluateurRecommandations` /
/// `RecommanderPlantes`), not persisted.
///
/// Answers the doc's three questions: **Quoi** = [planteId] (and the link to its
/// sheet — the "Comment"), **Pourquoi** = [raisons] (structured, localised at
/// the presentation layer). [score] (0..1) ranks the suggestions.
///
/// Domain names are kept in French; the code is documented in English.
class RecommandationPlante {
  final String _planteId;
  final double _score;
  final Set<RaisonReco> _raisons;

  RecommandationPlante._(this._planteId, this._score, this._raisons);

  /// Builds a recommendation. [score] must be in `0..1`.
  factory RecommandationPlante({
    required String planteId,
    required double score,
    required Set<RaisonReco> raisons,
  }) {
    assert(score >= 0 && score <= 1, 'score must be in 0..1');
    assert(planteId.isNotEmpty, 'planteId must not be empty');
    return RecommandationPlante._(
      planteId,
      score,
      Set<RaisonReco>.unmodifiable(raisons),
    );
  }

  /// Id of the recommended plant (links to its catalogue sheet).
  String get planteId => _planteId;

  /// Relevance score in `0..1` (higher = better suited), used for ranking.
  double get score => _score;

  /// Structured reasons behind the recommendation (unmodifiable).
  Set<RaisonReco> get raisons => _raisons;

  @override
  bool operator ==(Object other) =>
      other is RecommandationPlante &&
      other._planteId == _planteId &&
      other._score == _score &&
      _memesRaisons(other._raisons, _raisons);

  @override
  int get hashCode =>
      Object.hash(_planteId, _score, Object.hashAllUnordered(_raisons));

  static bool _memesRaisons(Set<RaisonReco> a, Set<RaisonReco> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  String toString() =>
      'RecommandationPlante($_planteId, score $_score, ${_raisons.length} raison(s))';
}
