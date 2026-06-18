import '../entities/fiche_plante.dart';
import '../enums/sens_association.dart';
import '../value_objects/association_benefique.dart';
import '../value_objects/association_conflit.dart';

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

/// A resolved companion paired with the typed [association] that links it to the
/// centre sheet — its mechanism and localised reason (ADR-0010). Used by views
/// to *explain* the relationship, not only list it.
///
/// [association] is always present: a companion only appears because some sheet
/// declared the relation. Its `mecanisme`/reason may still be unspecified for a
/// legacy curated pair.
class CompagnonAvecRaison<A> {
  final FichePlante _fiche;
  final A _association;
  final SensAssociation _sens;

  CompagnonAvecRaison(this._fiche, this._association, this._sens);

  /// The companion plant.
  FichePlante get fiche => _fiche;

  /// The typed association (an [AssociationBenefique] or [AssociationConflit])
  /// behind the relationship.
  A get association => _association;

  /// Direction seen from the centre (donne / recoit / mutuel, ADR-0012).
  SensAssociation get sens => _sens;
}

/// A sheet's companions within a catalogue, split by relationship kind.
///
/// Both lists are immutable. The numbers and the names a view shows derive from
/// the same object, so the Réseau and the detail sheet can never drift apart
/// (ADR-0008). Each companion carries its typed association so a view can show
/// *why* (ADR-0010); [bons]/[aEviter] expose the bare sheets for callers that
/// only need the names.
class CompagnonsResolus {
  final List<CompagnonAvecRaison<AssociationBenefique>> _bons;
  final List<CompagnonAvecRaison<AssociationConflit>> _aEviter;
  final List<FichePlante> _bonsFiches;
  final List<FichePlante> _aEviterFiches;

  CompagnonsResolus._(this._bons, this._aEviter)
      : _bonsFiches = List.unmodifiable(_bons.map((c) => c.fiche)),
        _aEviterFiches = List.unmodifiable(_aEviter.map((c) => c.fiche));

  /// Builds the result; both lists are stored unmodifiable.
  factory CompagnonsResolus({
    required List<CompagnonAvecRaison<AssociationBenefique>> bons,
    required List<CompagnonAvecRaison<AssociationConflit>> aEviter,
  }) =>
      CompagnonsResolus._(List.unmodifiable(bons), List.unmodifiable(aEviter));

  /// Good companions with their typed association (immutable, may be empty).
  List<CompagnonAvecRaison<AssociationBenefique>> get bonsDetailles => _bons;

  /// Companions to avoid with their typed association (immutable, may be empty).
  List<CompagnonAvecRaison<AssociationConflit>> get aEviterDetailles =>
      _aEviter;

  /// Good companions, sheets only (immutable, may be empty).
  List<FichePlante> get bons => _bonsFiches;

  /// Companions to avoid, sheets only (immutable, may be empty).
  List<FichePlante> get aEviter => _aEviterFiches;

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

  /// The beneficial association linking [a] and [b], preferring [a]'s own
  /// declaration and falling back to [b]'s (the relation is bidirectional, but
  /// source data is often filled on one side only). `null` when neither side
  /// declares a benefit.
  AssociationBenefique? beneficeEntre(FichePlante a, FichePlante b) =>
      a.associationBenefiqueAvec(b.id) ?? b.associationBenefiqueAvec(a.id);

  /// The conflicting association linking [a] and [b], with the same precedence
  /// as [beneficeEntre]. `null` when neither side declares a conflict.
  AssociationConflit? conflitEntre(FichePlante a, FichePlante b) =>
      a.associationConflitAvec(b.id) ?? b.associationConflitAvec(a.id);

  /// Direction of the **beneficial** relation seen from [centre] (ADR-0012):
  /// [SensAssociation.donne] when only [centre]'s sheet declares it,
  /// [SensAssociation.recoit] when only [autre]'s does, [SensAssociation.mutuel]
  /// when both. `null` when no benefit is declared either way.
  SensAssociation? sensBenefice(FichePlante centre, FichePlante autre) =>
      _sens(centre.associationBenefiqueAvec(autre.id) != null,
          autre.associationBenefiqueAvec(centre.id) != null);

  /// Direction of the **conflicting** relation seen from [centre] (ADR-0012),
  /// with the same rule as [sensBenefice].
  SensAssociation? sensConflit(FichePlante centre, FichePlante autre) =>
      _sens(centre.associationConflitAvec(autre.id) != null,
          autre.associationConflitAvec(centre.id) != null);

  static SensAssociation? _sens(bool centreDeclare, bool autreDeclare) {
    if (centreDeclare && autreDeclare) return SensAssociation.mutuel;
    if (centreDeclare) return SensAssociation.donne;
    if (autreDeclare) return SensAssociation.recoit;
    return null;
  }

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
    final bons = <CompagnonAvecRaison<AssociationBenefique>>[];
    final aEviter = <CompagnonAvecRaison<AssociationConflit>>[];
    for (final autre in catalogue) {
      switch (relationEntre(fiche, autre)) {
        case TypeCompagnonnage.bon:
          // Non-null: a `bon` relation means a benefit was declared on a side.
          bons.add(CompagnonAvecRaison(autre, beneficeEntre(fiche, autre)!,
              sensBenefice(fiche, autre)!));
        case TypeCompagnonnage.aEviter:
          aEviter.add(CompagnonAvecRaison(autre, conflitEntre(fiche, autre)!,
              sensConflit(fiche, autre)!));
        case TypeCompagnonnage.aucune:
          break;
      }
    }
    return CompagnonsResolus(bons: bons, aEviter: aEviter);
  }
}
