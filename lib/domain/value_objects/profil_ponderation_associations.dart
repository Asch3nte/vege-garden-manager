import '../enums/famille_effet_association.dart';
import '../enums/poids_association.dart';

/// A user's weighting profile for association effect families (ADR-0011): how
/// much each [FamilleEffetAssociation] counts when scoring derived suggestions.
///
/// Immutable value object. [defaut] is applied to everyone; an expert may
/// override families (via [avec]) and the override is persisted. A missing
/// family reads as [PoidsAssociation.normal], so the profile is always total.
class ProfilPonderationAssociations {
  final Map<FamilleEffetAssociation, PoidsAssociation> _poids;

  const ProfilPonderationAssociations._(this._poids);

  /// Builds a profile from explicit [poids] (stored unmodifiable). Families left
  /// out default to [PoidsAssociation.normal] when read.
  factory ProfilPonderationAssociations(
    Map<FamilleEffetAssociation, PoidsAssociation> poids,
  ) =>
      ProfilPonderationAssociations._(
        Map<FamilleEffetAssociation, PoidsAssociation>.unmodifiable(poids),
      );

  /// The neutral default profile applied to everyone: every family at
  /// [PoidsAssociation.normal] (ranking then driven by confidence). Calibrated
  /// here so the defaults live in one place.
  factory ProfilPonderationAssociations.defaut() => ProfilPonderationAssociations(
        {
          for (final f in FamilleEffetAssociation.values)
            f: PoidsAssociation.normal,
        },
      );

  /// Weight for [famille] (defaults to [PoidsAssociation.normal]).
  PoidsAssociation poids(FamilleEffetAssociation famille) =>
      _poids[famille] ?? PoidsAssociation.normal;

  /// Multiplier for [famille] — convenience for the scorer.
  double multiplicateur(FamilleEffetAssociation famille) =>
      poids(famille).multiplicateur;

  /// A copy with [famille] set to [valeur] (the expert tuning one slider).
  ProfilPonderationAssociations avec(
    FamilleEffetAssociation famille,
    PoidsAssociation valeur,
  ) =>
      ProfilPonderationAssociations({..._poids, famille: valeur});

  /// Whether this profile equals the neutral default (no override).
  bool get estDefaut => FamilleEffetAssociation.values
      .every((f) => poids(f) == PoidsAssociation.normal);

  @override
  bool operator ==(Object other) =>
      other is ProfilPonderationAssociations &&
      FamilleEffetAssociation.values.every((f) => poids(f) == other.poids(f));

  @override
  int get hashCode => Object.hashAll(
      [for (final f in FamilleEffetAssociation.values) poids(f)]);

  @override
  String toString() => 'ProfilPonderationAssociations('
      '${{for (final f in FamilleEffetAssociation.values) f.name: poids(f).name}})';
}
