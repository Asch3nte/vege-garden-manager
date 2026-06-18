import '../enums/type_conflit_association.dart';

/// A typed, optionally-explained **conflicting** companion association declared
/// by a plant towards another plant ([cibleId]).
///
/// Loaded from the YAML catalogue (`associations.defavorables[]`). [mecanismes]
/// names *why* the pairing is to be avoided (ADR-0010 Décision 1) — **possibly
/// several** (ADR-0012) ; empty for a legacy/curated pair that only states the
/// target. A free editorial reason ([raison], localised) may complete — or
/// nuance — the typed mechanisms. See `docs/05` §4.8.
///
/// Immutable value object: equality is by [cibleId], the set of [mecanismes]
/// and the localised reason map.
class AssociationConflit {
  final String _cibleId;
  final Set<TypeConflitAssociation> _mecanismes;
  final Map<String, String> _raisonI18n;

  const AssociationConflit._(
    this._cibleId,
    this._mecanismes,
    this._raisonI18n,
  ) : assert(_cibleId.length > 0, 'cibleId must not be empty');

  /// Builds the association. Provide either a single [mecanisme] (convenience,
  /// ADR-0010 style) **or** a set of [mecanismes] (ADR-0012), not both. The
  /// collections are stored unmodifiable and default to empty.
  factory AssociationConflit({
    required String cibleId,
    TypeConflitAssociation? mecanisme,
    Set<TypeConflitAssociation>? mecanismes,
    Map<String, String>? raisonI18n,
  }) {
    assert(mecanisme == null || mecanismes == null,
        'provide either mecanisme or mecanismes, not both');
    final set = mecanismes ??
        (mecanisme != null ? {mecanisme} : const <TypeConflitAssociation>{});
    return AssociationConflit._(
      cibleId,
      Set<TypeConflitAssociation>.unmodifiable(set),
      Map<String, String>.unmodifiable(raisonI18n ?? const {}),
    );
  }

  /// Id of the companion plant this association points to.
  String get cibleId => _cibleId;

  /// The mechanisms qualifying the conflict (unmodifiable, may be empty).
  Set<TypeConflitAssociation> get mecanismes => _mecanismes;

  /// Convenience: the first mechanism (ADR-0010 compatibility), or `null`.
  TypeConflitAssociation? get mecanisme =>
      _mecanismes.isEmpty ? null : _mecanismes.first;

  /// Whether at least one mechanism is declared.
  bool get aMecanisme => _mecanismes.isNotEmpty;

  /// Whether a free editorial reason is attached (in any locale).
  bool get aRaison => _raisonI18n.isNotEmpty;

  /// Free editorial reason for [locale], falling back to French, or `null` when
  /// the association carries none.
  String? raison(String locale) => _raisonI18n[locale] ?? _raisonI18n['fr'];

  @override
  bool operator ==(Object other) =>
      other is AssociationConflit &&
      other._cibleId == _cibleId &&
      _memesMecanismes(other._mecanismes, _mecanismes) &&
      _memesRaisons(other._raisonI18n, _raisonI18n);

  @override
  int get hashCode =>
      Object.hash(_cibleId, _mecanismes.length, _raisonI18n.length);

  @override
  String toString() => 'AssociationConflit($_cibleId, '
      '${_mecanismes.map((m) => m.name).join('+')})';

  static bool _memesMecanismes(
    Set<TypeConflitAssociation> a,
    Set<TypeConflitAssociation> b,
  ) =>
      a.length == b.length && a.containsAll(b);

  static bool _memesRaisons(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
