import '../enums/famille_effet_association.dart';
import '../enums/famille_effet_conflit.dart';
import '../enums/poids_association.dart';

/// A user's weighting profile for association effect families (ADR-0011): how
/// much each [FamilleEffetAssociation] counts when scoring derived suggestions.
///
/// Immutable value object. [defaut] is applied to everyone; an expert may
/// override families (via [avec]) and the override is persisted. A missing
/// family reads as [PoidsAssociation.normal], so the profile is always total.
class ProfilPonderationAssociations {
  final Map<FamilleEffetAssociation, PoidsAssociation> _poids;
  final Map<FamilleEffetConflit, PoidsAssociation> _poidsConflit;

  const ProfilPonderationAssociations._(this._poids, this._poidsConflit);

  /// Builds a profile from explicit benefit [poids] and conflict
  /// [poidsConflit] (ADR-0014). Families left out read as
  /// [PoidsAssociation.normal].
  factory ProfilPonderationAssociations(
    Map<FamilleEffetAssociation, PoidsAssociation> poids, {
    Map<FamilleEffetConflit, PoidsAssociation> poidsConflit = const {},
  }) =>
      ProfilPonderationAssociations._(
        Map<FamilleEffetAssociation, PoidsAssociation>.unmodifiable(poids),
        Map<FamilleEffetConflit, PoidsAssociation>.unmodifiable(poidsConflit),
      );

  /// The neutral default profile applied to everyone: every family (benefit
  /// **and** conflict) at [PoidsAssociation.normal].
  factory ProfilPonderationAssociations.defaut() => ProfilPonderationAssociations(
        {
          for (final f in FamilleEffetAssociation.values)
            f: PoidsAssociation.normal,
        },
        poidsConflit: {
          for (final f in FamilleEffetConflit.values) f: PoidsAssociation.normal,
        },
      );

  /// Weight for a benefit [famille] (defaults to [PoidsAssociation.normal]).
  PoidsAssociation poids(FamilleEffetAssociation famille) =>
      _poids[famille] ?? PoidsAssociation.normal;

  /// Weight for a conflict [famille] (defaults to [PoidsAssociation.normal]).
  PoidsAssociation poidsConflit(FamilleEffetConflit famille) =>
      _poidsConflit[famille] ?? PoidsAssociation.normal;

  /// Multiplier for a benefit [famille] — convenience for the scorer.
  double multiplicateur(FamilleEffetAssociation famille) =>
      poids(famille).multiplicateur;

  /// Multiplier for a conflict [famille] (ADR-0014).
  double multiplicateurConflit(FamilleEffetConflit famille) =>
      poidsConflit(famille).multiplicateur;

  /// A copy with a benefit [famille] set to [valeur].
  ProfilPonderationAssociations avec(
    FamilleEffetAssociation famille,
    PoidsAssociation valeur,
  ) =>
      ProfilPonderationAssociations({..._poids, famille: valeur},
          poidsConflit: _poidsConflit);

  /// A copy with a conflict [famille] set to [valeur] (ADR-0014).
  ProfilPonderationAssociations avecConflit(
    FamilleEffetConflit famille,
    PoidsAssociation valeur,
  ) =>
      ProfilPonderationAssociations(_poids,
          poidsConflit: {..._poidsConflit, famille: valeur});

  /// Whether this profile equals the neutral default (no override on either side).
  bool get estDefaut =>
      FamilleEffetAssociation.values
          .every((f) => poids(f) == PoidsAssociation.normal) &&
      FamilleEffetConflit.values
          .every((f) => poidsConflit(f) == PoidsAssociation.normal);

  @override
  bool operator ==(Object other) =>
      other is ProfilPonderationAssociations &&
      FamilleEffetAssociation.values.every((f) => poids(f) == other.poids(f)) &&
      FamilleEffetConflit.values
          .every((f) => poidsConflit(f) == other.poidsConflit(f));

  @override
  int get hashCode => Object.hashAll([
        for (final f in FamilleEffetAssociation.values) poids(f),
        for (final f in FamilleEffetConflit.values) poidsConflit(f),
      ]);

  @override
  String toString() => 'ProfilPonderationAssociations('
      '${{for (final f in FamilleEffetAssociation.values) f.name: poids(f).name}}, '
      'conflits=${{for (final f in FamilleEffetConflit.values) f.name: poidsConflit(f).name}})';
}
