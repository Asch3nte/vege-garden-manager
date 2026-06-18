import '../../domain/enums/critere_association.dart';
import '../../domain/enums/niveau_confiance.dart';
import '../../domain/enums/sens_association.dart';
import '../../domain/enums/type_benefice_association.dart';
import '../../domain/enums/type_conflit_association.dart';

/// A companion-planting relationship **derived** by the engine (ADR-0010, Lot 3)
/// between a centre plant and the plant identified by [cibleId].
///
/// Sealed: a suggestion is either a [SuggestionBenefique] or a
/// [SuggestionConflit], so callers `switch` on the concrete type to read the
/// typed mechanism. Every suggestion carries a [confiance], a [sens] (direction
/// seen from the centre, ADR-0012) and, when the rule hinges on a specific
/// bioaggressor (repulsion / trap), the [slug] involved — the presentation layer
/// builds a localised reason from these.
sealed class SuggestionAssociation {
  final String _cibleId;
  final NiveauConfiance _confiance;
  final SensAssociation _sens;
  final String? _slug;
  final Set<CritereAssociation> _criteres;

  const SuggestionAssociation(
      this._cibleId, this._confiance, this._sens, this._slug, this._criteres);

  /// Id of the other plant this suggestion relates the centre to.
  String get cibleId => _cibleId;

  /// How confident the inference is.
  NiveauConfiance get confiance => _confiance;

  /// Direction seen from the centre (donne / recoit / mutuel).
  SensAssociation get sens => _sens;

  /// Bioaggressor slug the rule hinges on (repulsion / trap), else `null`.
  String? get slug => _slug;

  /// Every criterion that the engine evaluated and found true for this
  /// suggestion (ADR-0014) — the full, explicit evidence behind it.
  Set<CritereAssociation> get criteres => _criteres;
}

/// A derived **beneficial** suggestion qualified by its [mecanisme].
final class SuggestionBenefique extends SuggestionAssociation {
  final TypeBeneficeAssociation _mecanisme;

  SuggestionBenefique._(
    this._mecanisme,
    String cibleId,
    NiveauConfiance confiance,
    SensAssociation sens,
    String? slug,
    Set<CritereAssociation> criteres,
  ) : super(cibleId, confiance, sens, slug, criteres);

  /// Builds a beneficial suggestion. [sens] defaults to [SensAssociation.donne]
  /// (the engine derives `a → b` as "a gives to b").
  factory SuggestionBenefique({
    required String cibleId,
    required TypeBeneficeAssociation mecanisme,
    required NiveauConfiance confiance,
    SensAssociation sens = SensAssociation.donne,
    String? slug,
    Set<CritereAssociation> criteres = const {},
  }) =>
      SuggestionBenefique._(mecanisme, cibleId, confiance, sens, slug, criteres);

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
    SensAssociation sens,
    String? slug,
    Set<CritereAssociation> criteres,
  ) : super(cibleId, confiance, sens, slug, criteres);

  /// Builds a conflicting suggestion. [sens] defaults to [SensAssociation.donne].
  factory SuggestionConflit({
    required String cibleId,
    required TypeConflitAssociation mecanisme,
    required NiveauConfiance confiance,
    SensAssociation sens = SensAssociation.donne,
    String? slug,
    Set<CritereAssociation> criteres = const {},
  }) =>
      SuggestionConflit._(mecanisme, cibleId, confiance, sens, slug, criteres);

  /// The conflict mechanism inferred.
  TypeConflitAssociation get mecanisme => _mecanisme;
}
