import 'type_benefice_association.dart';

/// Thematic family a *beneficial* association mechanism belongs to (ADR-0011).
///
/// Grouping the ten benefit mechanisms into a handful of families lets the user
/// weight associations by **theme** (a few sliders) rather than per mechanism,
/// and lets the UI/recommendation rank suggestions by what the gardener values.
enum FamilleEffetAssociation {
  /// Making the most of space/light: living support, layering, succession.
  gainDePlace,

  /// Keeping pests away: repelling, trapping, scent confusion.
  protectionRavageurs,

  /// Feeding the soil: nitrogen fixation.
  fertilite,

  /// Bringing pollinators to entomophilous neighbours.
  pollinisation,

  /// Protecting the ground/plants: cover crop, windbreak.
  couvertureAbri,
}

/// The effect family of a benefit [mecanisme] — the **single source of truth**
/// for the mechanism→family mapping (ADR-0011), exhaustive by construction.
FamilleEffetAssociation familleDe(TypeBeneficeAssociation mecanisme) =>
    switch (mecanisme) {
      TypeBeneficeAssociation.tuteurStructurel ||
      TypeBeneficeAssociation.etagementLumiere ||
      TypeBeneficeAssociation.successionTemporelle =>
        FamilleEffetAssociation.gainDePlace,
      TypeBeneficeAssociation.repulsionRavageur ||
      TypeBeneficeAssociation.plantePiege ||
      TypeBeneficeAssociation.brouillageOlfactif =>
        FamilleEffetAssociation.protectionRavageurs,
      TypeBeneficeAssociation.fixationAzote => FamilleEffetAssociation.fertilite,
      TypeBeneficeAssociation.attractionPollinisateurs =>
        FamilleEffetAssociation.pollinisation,
      TypeBeneficeAssociation.couvreSol ||
      TypeBeneficeAssociation.briseVent =>
        FamilleEffetAssociation.couvertureAbri,
    };

/// The set of effect families covered by [mecanismes] (ADR-0012) — used to label
/// an association by family rather than by each precise mechanism.
Set<FamilleEffetAssociation> famillesDe(
        Iterable<TypeBeneficeAssociation> mecanismes) =>
    {for (final m in mecanismes) familleDe(m)};
