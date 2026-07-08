import '../enums/phase_sensible_eau.dart';

/// Immutable, **optional** detailed watering guidance carried by a fiche's
/// [BesoinsCulture] (the coarse [BesoinEau] term stays for every tier; this
/// detail is only surfaced to expert users, ADR-0009 / `acces.eauDetaillee`).
///
/// Every aspect is **independently optional** on purpose: per-plant frequency
/// and volume figures must be *real* (sourced from horticultural references),
/// never invented, so a fiche may legitimately carry only the well-documented
/// [phasesSensibles] and an editorial [note] while leaving the numbers unset.
///
/// The numeric ranges are **indicative for warm, dry weather** — actual
/// scheduling is the engine's job (`BilanArrosage` combines soil, weather and
/// equipment). This value object is purely informational and not persisted.
///
/// At least one aspect must be populated (a fully empty detail is meaningless
/// and would never be built from YAML).
///
/// Domain names are kept in French; the code is documented in English.
class ArrosageDetaille {
  final int? _frequenceJoursMin;
  final int? _frequenceJoursMax;
  final double? _volumeLitresM2Min;
  final double? _volumeLitresM2Max;
  final Set<PhaseSensibleEau> _phasesSensibles;
  final Map<String, String> _noteI18n;

  ArrosageDetaille._(
    this._frequenceJoursMin,
    this._frequenceJoursMax,
    this._volumeLitresM2Min,
    this._volumeLitresM2Max,
    this._phasesSensibles,
    this._noteI18n,
  )   : assert(
          (_frequenceJoursMin == null) == (_frequenceJoursMax == null),
          'frequence: provide both bounds or neither',
        ),
        assert(
          _frequenceJoursMin == null || _frequenceJoursMin > 0,
          'frequence bounds must be strictly positive (days)',
        ),
        assert(
          _frequenceJoursMin == null || _frequenceJoursMin <= _frequenceJoursMax!,
          'frequence: min must be <= max',
        ),
        assert(
          (_volumeLitresM2Min == null) == (_volumeLitresM2Max == null),
          'volume: provide both bounds or neither',
        ),
        assert(
          _volumeLitresM2Min == null || _volumeLitresM2Min > 0,
          'volume bounds must be strictly positive (L/m²)',
        ),
        assert(
          _volumeLitresM2Min == null || _volumeLitresM2Min <= _volumeLitresM2Max!,
          'volume: min must be <= max',
        );

  /// Builds a detailed watering guidance. Provide [frequenceJoursMin]/[Max] as a
  /// pair (or neither) and likewise [volumeLitresM2Min]/[Max]. At least one of
  /// frequency, volume, [phasesSensibles] or [noteI18n] must be populated.
  factory ArrosageDetaille({
    int? frequenceJoursMin,
    int? frequenceJoursMax,
    double? volumeLitresM2Min,
    double? volumeLitresM2Max,
    Set<PhaseSensibleEau> phasesSensibles = const {},
    Map<String, String> noteI18n = const {},
  }) {
    final aFrequence = frequenceJoursMin != null || frequenceJoursMax != null;
    final aVolume = volumeLitresM2Min != null || volumeLitresM2Max != null;
    assert(
      aFrequence || aVolume || phasesSensibles.isNotEmpty || noteI18n.isNotEmpty,
      'ArrosageDetaille must carry at least one populated aspect',
    );
    return ArrosageDetaille._(
      frequenceJoursMin,
      frequenceJoursMax,
      volumeLitresM2Min,
      volumeLitresM2Max,
      Set<PhaseSensibleEau>.unmodifiable(phasesSensibles),
      Map<String, String>.unmodifiable(noteI18n),
    );
  }

  /// Lower bound of the indicative interval between waterings (days), or `null`.
  int? get frequenceJoursMin => _frequenceJoursMin;

  /// Upper bound of the indicative interval between waterings (days), or `null`.
  int? get frequenceJoursMax => _frequenceJoursMax;

  /// Whether an indicative watering frequency is provided.
  bool get aFrequence => _frequenceJoursMin != null;

  /// Lower bound of the indicative volume per watering (L/m²), or `null`.
  double? get volumeLitresM2Min => _volumeLitresM2Min;

  /// Upper bound of the indicative volume per watering (L/m²), or `null`.
  double? get volumeLitresM2Max => _volumeLitresM2Max;

  /// Whether an indicative watering volume is provided.
  bool get aVolume => _volumeLitresM2Min != null;

  /// Growth stages most sensitive to water stress (unmodifiable, may be empty).
  Set<PhaseSensibleEau> get phasesSensibles => _phasesSensibles;

  /// Whether at least one sensitive growth stage is declared.
  bool get aPhasesSensibles => _phasesSensibles.isNotEmpty;

  /// Whether an editorial note is attached (in any locale).
  bool get aNote => _noteI18n.isNotEmpty;

  /// Editorial note for [locale], falling back to French, or `null` when none.
  String? note(String locale) => _noteI18n[locale] ?? _noteI18n['fr'];

  @override
  bool operator ==(Object other) =>
      other is ArrosageDetaille &&
      other._frequenceJoursMin == _frequenceJoursMin &&
      other._frequenceJoursMax == _frequenceJoursMax &&
      other._volumeLitresM2Min == _volumeLitresM2Min &&
      other._volumeLitresM2Max == _volumeLitresM2Max &&
      _memesPhases(other._phasesSensibles, _phasesSensibles) &&
      _memesNotes(other._noteI18n, _noteI18n);

  @override
  int get hashCode => Object.hash(
        _frequenceJoursMin,
        _frequenceJoursMax,
        _volumeLitresM2Min,
        _volumeLitresM2Max,
        _phasesSensibles.length,
        _noteI18n.length,
      );

  @override
  String toString() => 'ArrosageDetaille('
      'freq: ${_frequenceJoursMin ?? '-'}–${_frequenceJoursMax ?? '-'} j, '
      'vol: ${_volumeLitresM2Min ?? '-'}–${_volumeLitresM2Max ?? '-'} L/m², '
      'phases: ${_phasesSensibles.map((p) => p.name).join('+')})';

  static bool _memesPhases(Set<PhaseSensibleEau> a, Set<PhaseSensibleEau> b) =>
      a.length == b.length && a.containsAll(b);

  static bool _memesNotes(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
