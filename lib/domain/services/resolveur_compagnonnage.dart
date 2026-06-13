import '../entities/fiche_plante.dart';

/// The kind of companion-planting relationship between two plant sheets
/// (ADR-0008).
enum TypeCompagnonnage {
  /// Good companions — they benefit from being grown near each other.
  bon,

  /// To avoid — they should be kept apart.
  aEviter,

  /// No relationship declared either way.
  aucune,
}

/// A sheet's companions within a catalogue, split by relationship kind.
///
/// Both lists are immutable. The numbers and the names a view shows derive from
/// the same object, so the Réseau and the detail sheet can never drift apart
/// (ADR-0008).
class CompagnonsResolus {
  final List<FichePlante> _bons;
  final List<FichePlante> _aEviter;

  CompagnonsResolus._(this._bons, this._aEviter);

  /// Builds the result; both lists are stored unmodifiable.
  factory CompagnonsResolus({
    required List<FichePlante> bons,
    required List<FichePlante> aEviter,
  }) =>
      CompagnonsResolus._(List.unmodifiable(bons), List.unmodifiable(aEviter));

  /// Good companions (immutable, may be empty).
  List<FichePlante> get bons => _bons;

  /// Companions to avoid (immutable, may be empty).
  List<FichePlante> get aEviter => _aEviter;

  /// Number of good companions.
  int get nbBons => _bons.length;

  /// Number of companions to avoid.
  int get nbAEviter => _aEviter.length;
}

/// Resolves companion-planting associations between plant sheets under a single
/// canonical semantic, shared by every view so their counts and lists always
/// coincide (ADR-0008):
///
/// - **Bidirectional** — the relation holds as soon as *either* sheet declares
///   it; source data is often filled on one side only.
/// - **Good takes precedence** — a pair that is good one way and to avoid the
///   other counts once, as good.
///
/// Pure domain logic: it relies only on the entity's public predicates
/// ([FichePlante.sAssocieBienAvec] / [FichePlante.entreEnConflitAvec]), so it
/// respects the entity's encapsulation and is independent of any catalogue
/// filter.
class ResolveurCompagnonnage {
  const ResolveurCompagnonnage();

  /// Whether [a] and [b] are good companions — true as soon as either sheet
  /// declares the benefit.
  bool sontBonsCompagnons(FichePlante a, FichePlante b) =>
      a.sAssocieBienAvec(b.id) || b.sAssocieBienAvec(a.id);

  /// Whether [a] and [b] should be kept apart — true as soon as either sheet
  /// declares the conflict.
  bool sontAEviter(FichePlante a, FichePlante b) =>
      a.entreEnConflitAvec(b.id) || b.entreEnConflitAvec(a.id);

  /// The relationship between [a] and [b]: [TypeCompagnonnage.bon] wins over
  /// [TypeCompagnonnage.aEviter] (precedence); [TypeCompagnonnage.aucune] when
  /// neither sheet declares anything, and always for a sheet with itself.
  TypeCompagnonnage relationEntre(FichePlante a, FichePlante b) {
    if (a.id == b.id) return TypeCompagnonnage.aucune;
    if (sontBonsCompagnons(a, b)) return TypeCompagnonnage.bon;
    if (sontAEviter(a, b)) return TypeCompagnonnage.aEviter;
    return TypeCompagnonnage.aucune;
  }

  /// Companions of [fiche] among [catalogue], split into good / to-avoid and
  /// excluding [fiche] itself. Order follows [catalogue]; callers sort for
  /// display as needed.
  CompagnonsResolus resoudre(
    FichePlante fiche,
    Iterable<FichePlante> catalogue,
  ) {
    final bons = <FichePlante>[];
    final aEviter = <FichePlante>[];
    for (final autre in catalogue) {
      switch (relationEntre(fiche, autre)) {
        case TypeCompagnonnage.bon:
          bons.add(autre);
        case TypeCompagnonnage.aEviter:
          aEviter.add(autre);
        case TypeCompagnonnage.aucune:
          break;
      }
    }
    return CompagnonsResolus(bons: bons, aEviter: aEviter);
  }
}
