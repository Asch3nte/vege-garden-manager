/// Whether a family-level bioaggressor is a disease or an animal pest.
///
/// Used by the bioaggressor reference to qualify each slug
/// listed in a family's `maladies_communes` / `ravageurs_communs`.
enum TypeBioagresseur {
  /// A disease (caused by a fungus, oomycete, bacterium, virus…), e.g. mildew.
  maladie,

  /// An animal pest (insect, mite, mollusc, nematode…), e.g. aphid.
  ravageur,
}
