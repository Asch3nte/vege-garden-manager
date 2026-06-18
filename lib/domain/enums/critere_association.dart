/// A single, explicit **criterion** that the derivation engine evaluated and
/// found true when inferring an association (ADR-0014, Décision 1).
///
/// Every derived [SuggestionAssociation] carries the **set** of criteria that
/// produced it, so the UI can list *all* the variables behind the
/// recommendation — with their real values — instead of a vague confidence
/// phrase. Criteria are phrased by **role**: `source` is the plant providing the
/// service / driving the conflict, `cible` the other one; symmetric criteria
/// (`deux…`, `meme…`) concern both.
///
/// The full set is declared up-front (stable across lots); each rule emits the
/// subset it checks (some are activated in later ADR-0014 lots).
enum CritereAssociation {
  // — Fixation d'azote —
  sourceFixeAzote,
  cibleGourmandeAzote,

  // — Pollinisation —
  sourceAttirePollinisateurs,
  cibleEntomophile,

  // — Auxiliaires (prédateurs/parasitoïdes) —
  sourceAttireAuxiliaires,
  cibleSujetteRavageurs,

  // — Tuteur structurel —
  sourceSupport,
  sourcePlusHaute,
  cibleGrimpante,

  // — Étagement / ombre —
  sourceHaute,
  cibleNettementPlusBasse,
  ciblePrefereOmbre,
  cibleTolereOmbre,

  // — Succession temporelle —
  cyclesComplementaires,
  occupationsDecalees,

  // — Couverture / abri —
  sourceCouvreSol,
  sourceBriseVent,

  // — Brouillage olfactif —
  deuxAromatiques,
  uneRepulsive,

  // — Répulsion / plante-piège (bioagresseur ciblé) —
  sourceRepulsiveCible,
  sourcePiegeCible,

  // — Ameublissement du sol —
  sourceRacineProfonde,
  cibleRacineSuperficielle,

  // — Conflits —
  memeFamille,
  deuxHautesPleinSoleil,
  deuxGourmandesAzote,
  deuxAssoiffees,
  deuxEtalees,
  maladieCommune,
}
