/// Root system depth/shape of a plant (ADR-0014, Décision 0).
///
/// Used by the association engine to reason about **soil structuring** (a deep
/// or taproot plant loosens the soil for a shallow-rooted neighbour) and to
/// refine root competition. Optional on a sheet: a rule that needs it is skipped
/// when it is unknown (no invented data).
enum EnracinementPlante {
  /// Shallow, near-surface roots (e.g. lettuce, onion).
  superficiel,

  /// Moderately deep fibrous roots (e.g. most brassicas).
  moyen,

  /// Deep fibrous/branched roots reaching well below the surface (e.g. tomato).
  profond,

  /// A single deep taproot that breaks up compacted soil (e.g. carrot, radish,
  /// daikon) — the strongest soil-loosener.
  pivotant,
}
