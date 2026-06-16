import '../enums/type_benefice_association.dart';

/// A typed, optionally-explained **beneficial** companion association declared
/// by a plant towards another plant ([cibleId]).
///
/// Loaded from the YAML catalogue (`associations.beneficies[]`). The [mecanisme]
/// names *why* the pairing helps (ADR-0010, Décision 1); it is `null` for a
/// legacy/curated pair that only states the target without qualifying it. A free
/// editorial reason ([raison], localised) may complete — or nuance — the typed
/// mechanism. See `docs/05` §4.8.
///
/// Immutable value object: equality is by [cibleId], [mecanisme] and the
/// localised reason map.
class AssociationBenefique {
  final String _cibleId;
  final TypeBeneficeAssociation? _mecanisme;
  final Map<String, String> _raisonI18n;

  const AssociationBenefique._(
    this._cibleId,
    this._mecanisme,
    this._raisonI18n,
  ) : assert(_cibleId.length > 0, 'cibleId must not be empty');

  /// Builds the association. [cibleId] must not be empty; the reason map is
  /// stored unmodifiable and defaults to empty.
  factory AssociationBenefique({
    required String cibleId,
    TypeBeneficeAssociation? mecanisme,
    Map<String, String>? raisonI18n,
  }) =>
      AssociationBenefique._(
        cibleId,
        mecanisme,
        Map<String, String>.unmodifiable(raisonI18n ?? const {}),
      );

  /// Id of the companion plant this association points to.
  String get cibleId => _cibleId;

  /// The mechanism qualifying the benefit, or `null` when unspecified.
  TypeBeneficeAssociation? get mecanisme => _mecanisme;

  /// Whether a free editorial reason is attached (in any locale).
  bool get aRaison => _raisonI18n.isNotEmpty;

  /// Free editorial reason for [locale], falling back to French, or `null` when
  /// the association carries none.
  String? raison(String locale) => _raisonI18n[locale] ?? _raisonI18n['fr'];

  @override
  bool operator ==(Object other) =>
      other is AssociationBenefique &&
      other._cibleId == _cibleId &&
      other._mecanisme == _mecanisme &&
      _memesRaisons(other._raisonI18n, _raisonI18n);

  @override
  int get hashCode => Object.hash(_cibleId, _mecanisme, _raisonI18n.length);

  @override
  String toString() =>
      'AssociationBenefique($_cibleId, ${_mecanisme?.name ?? '—'})';

  static bool _memesRaisons(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
