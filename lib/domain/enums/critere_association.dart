/// A single, explicit **criterion** that the derivation engine evaluated and
/// found true when inferring an association.
///
/// Every derived [SuggestionAssociation] carries the **set** of criteria that
/// produced it, so the UI can list *all* the variables behind the
/// recommendation — with their real values — instead of a vague confidence
/// phrase. Criteria are phrased by **role**: `source` is the plant providing the
/// service / driving the conflict, `cible` the other one; symmetric criteria
/// (`deux…`, `meme…`) concern both.
///
/// The full set is declared up-front; each rule emits the subset it checks.
enum CritereAssociation {
  // — Nitrogen fixation —
  sourceFixeAzote,
  cibleGourmandeAzote,

  // — Pollination —
  sourceAttirePollinisateurs,
  cibleEntomophile,

  // — Beneficial insects (predators/parasitoids) —
  sourceAttireAuxiliaires,
  cibleSujetteRavageurs,

  // — Structural support —
  sourceSupport,
  sourcePlusHaute,
  cibleGrimpante,

  // — Layering / shade —
  sourceHaute,
  cibleNettementPlusBasse,
  ciblePrefereOmbre,
  cibleTolereOmbre,

  // — Succession in time —
  cyclesComplementaires,
  occupationsDecalees,

  // — Ground cover / shelter —
  sourceCouvreSol,
  sourceBriseVent,

  // — Scent masking —
  deuxAromatiques,
  uneRepulsive,

  // — Repellent / trap plant (targeted bioaggressor) —
  sourceRepulsiveCible,
  sourcePiegeCible,

  // — Soil loosening —
  sourceRacineProfonde,
  cibleRacineSuperficielle,

  // — Conflicts —
  memeFamille,
  deuxHautesPleinSoleil,
  deuxGourmandesAzote,
  deuxAssoiffees,
  deuxEtalees,
  maladieCommune,
}
