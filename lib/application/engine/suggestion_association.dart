import '../../domain/enums/niveau_confiance.dart';
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_conflit_association.dart';

/// A companion-planting relationship **derived** by the engine (ADR-0010, Lot 3)
/// between a centre plant and the plant identified by [cibleId].
///
/// Sealed: a suggestion is either a [SuggestionBenefique] or a
/// [SuggestionConflit], so callers `switch` on the concrete type to read the
/// typed mechanism. Every suggestion carries a [confiance] and, when the rule
/// hinges on a specific bioaggressor (repulsion / trap), the [slug] involved —
/// the presentation layer builds a localised reason from these.
sealed class SuggestionAssociation {
  final String _cibleId;
  final NiveauConfiance _confiance;
  final String? _slug;

  const SuggestionAssociation(this._cibleId, this._confiance, this._slug);

  /// Id of the other plant this suggestion relates the centre to.
  String get cibleId => _cibleId;

  /// How confident the inference is.
  NiveauConfiance get confiance => _confiance;

  /// Bioaggressor slug the rule hinges on (repulsion / trap), else `null`.
  String? get slug => _slug;
}

/// A derived **beneficial** suggestion qualified by its [mecanisme].
final class SuggestionBenefique extends SuggestionAssociation {
  final TypeBeneficeAssociation _mecanisme;

  SuggestionBenefique._(
    this._mecanisme,
    String cibleId,
    NiveauConfiance confiance,
    String? slug,
  ) : super(cibleId, confiance, slug);

  /// Builds a beneficial suggestion.
  factory SuggestionBenefique({
    required String cibleId,
    required TypeBeneficeAssociation mecanisme,
    required NiveauConfiance confiance,
    String? slug,
  }) =>
      SuggestionBenefique._(mecanisme, cibleId, confiance, slug);

  /// The benefit mechanism inferred.
  TypeBeneficeAssociation get mecanisme => _mecanisme;
}

/// A derived **conflicting** suggestion qualified by its [mecanisme].
final class SuggestionConflit extends SuggestionAssociation {
  final TypeConflitAssociation _mecanisme;

  SuggestionConflit._(
    this._mecanisme,
    String cibleId,
    NiveauConfiance confiance,
    String? slug,
  ) : super(cibleId, confiance, slug);

  /// Builds a conflicting suggestion.
  factory SuggestionConflit({
    required String cibleId,
    required TypeConflitAssociation mecanisme,
    required NiveauConfiance confiance,
    String? slug,
  }) =>
      SuggestionConflit._(mecanisme, cibleId, confiance, slug);

  /// The conflict mechanism inferred.
  TypeConflitAssociation get mecanisme => _mecanisme;
}
