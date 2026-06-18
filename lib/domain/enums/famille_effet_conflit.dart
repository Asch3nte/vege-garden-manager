import 'type_conflit_association.dart';

/// Thematic family a *conflict* mechanism belongs to (ADR-0014, Décision 8).
///
/// Mirrors [FamilleEffetAssociation] for benefits: grouping the conflict
/// mechanisms into a handful of families lets the user **weight** (or ignore) a
/// whole class of warnings — e.g. raise *risque sanitaire* if disease pressure
/// is their concern, or ignore *concurrence ressources* when they have room.
enum FamilleEffetConflit {
  /// Competing for light, water, space or nitrogen.
  concurrenceRessources,

  /// Sharing pests/diseases (same family or a common pathogen).
  risqueSanitaire,

  /// Chemical inhibition (allelopathy).
  allelopathie,
}

/// The conflict family of a [mecanisme] — single source of truth, exhaustive by
/// construction (ADR-0014).
FamilleEffetConflit familleConflitDe(TypeConflitAssociation mecanisme) =>
    switch (mecanisme) {
      TypeConflitAssociation.competitionLumiere ||
      TypeConflitAssociation.competitionAzote ||
      TypeConflitAssociation.competitionEau ||
      TypeConflitAssociation.competitionEspace =>
        FamilleEffetConflit.concurrenceRessources,
      TypeConflitAssociation.memeFamilleRavageurs ||
      TypeConflitAssociation.partageMaladies =>
        FamilleEffetConflit.risqueSanitaire,
      TypeConflitAssociation.allelopathie => FamilleEffetConflit.allelopathie,
    };
