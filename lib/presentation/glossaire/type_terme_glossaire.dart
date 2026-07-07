/// The kind of a glossary term (ADR-0017, D1).
///
/// The type drives the **visual identity** of the term across the app: the
/// colour of its badge on the term page and of every clickable occurrence
/// (`TermeCliquable`, wiki links — D2/D5). The chart itself lives in the
/// design system (theme extension, docs/08).
enum TypeTermeGlossaire {
  /// A botanical family (derived from the YAML family reference).
  famille,

  /// A disease (derived from the YAML bioaggressor reference).
  maladie,

  /// A pest (derived from the YAML bioaggressor reference).
  ravageur,

  /// A concrete garden tool / equipment (one page per `TypeEquipement` value).
  outil,

  /// Any other concept: business enums, transverse gardening notions.
  notion,
}
