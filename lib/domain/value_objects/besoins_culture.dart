import '../enums/besoin_eau.dart';
import '../enums/niveau_soleil.dart';
import '../enums/qualite_sol.dart';


/// Immutable value object describing a plant's agronomic needs (the "desired"
/// side, carried by a fiche): water, sun, soil qualities and a pH window.
///
/// [soleil] is the *preferred* sun level; [soleilMin] is the minimum tolerated
/// (e.g. a tomato prefers [NiveauSoleil.pleinSoleil] but can manage with
/// [NiveauSoleil.miOmbre]). When [soleilMin] is `null` the engine falls back
/// to a simple distance-based score.
///
/// To be distinguished from the texture a parcelle actually *has*: matching the
/// two is the engine's job (`docs/05-modele-de-domaine.md` §4.4 & §4.5/D7).
/// See also `docs/16-enrichissement-fiches-plantes.md` §I.
///
/// Domain names are kept in French; the code is documented in English.
class BesoinsCulture {
  final BesoinEau _eau;
  final NiveauSoleil _soleil;
  final NiveauSoleil? _soleilMin;
  final Set<QualiteSol> _qualitesSol;
  final double _phMin;
  final double _phMax;

  const BesoinsCulture._(
    this._eau,
    this._soleil,
    this._soleilMin,
    this._qualitesSol,
    this._phMin,
    this._phMax,
  )   : assert(_phMin >= 0 && _phMin <= 14, 'phMin must be in 0..14'),
        assert(_phMax >= 0 && _phMax <= 14, 'phMax must be in 0..14'),
        assert(_phMin <= _phMax, 'phMin must be <= phMax');

  /// Creates a set of needs. [phMin] and [phMax] must be in 0..14 with
  /// `phMin <= phMax`. [qualitesSol] may be empty (no specific preference).
  /// [soleilMin] is the minimum tolerated sun level (optional; `null` = use
  /// distance-based scoring only).
  factory BesoinsCulture({
    required BesoinEau eau,
    required NiveauSoleil soleil,
    required double phMin,
    required double phMax,
    Set<QualiteSol> qualitesSol = const {},
    NiveauSoleil? soleilMin,
  }) =>
      BesoinsCulture._(
        eau,
        soleil,
        soleilMin,
        Set.unmodifiable(qualitesSol),
        phMin,
        phMax,
      );

  /// Preferred sun level.
  NiveauSoleil get soleil => _soleil;

  /// Minimum tolerated sun level, or `null` when not specified.
  NiveauSoleil? get soleilMin => _soleilMin;

  /// Qualitative water need.
  BesoinEau get eau => _eau;

  /// Desired soil qualities (unmodifiable, possibly empty).
  Set<QualiteSol> get qualitesSol => _qualitesSol;

  /// Lower bound of the preferred pH window (0–14).
  double get phMin => _phMin;

  /// Upper bound of the preferred pH window (0–14).
  double get phMax => _phMax;

  /// Whether [ph] falls within the preferred pH window (bounds inclusive).
  bool acceptePh(double ph) => ph >= _phMin && ph <= _phMax;

  @override
  bool operator ==(Object other) =>
      other is BesoinsCulture &&
      other._eau == _eau &&
      other._soleil == _soleil &&
      other._soleilMin == _soleilMin &&
      other._phMin == _phMin &&
      other._phMax == _phMax &&
      other._qualitesSol.length == _qualitesSol.length &&
      other._qualitesSol.containsAll(_qualitesSol);

  @override
  int get hashCode {
    final qualitesHash = _qualitesSol.fold(0, (h, q) => h ^ q.hashCode);
    return Object.hash(_eau, _soleil, _soleilMin, _phMin, _phMax, qualitesHash);
  }

  @override
  String toString() => 'BesoinsCulture(eau: ${_eau.name}, soleil: '
      '${_soleil.name}, soleilMin: ${_soleilMin?.name}, '
      'pH: $_phMin–$_phMax, sol: $_qualitesSol)';
}
