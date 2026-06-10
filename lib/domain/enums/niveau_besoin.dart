/// Qualitative need level — reusable for nutrient needs (azote, etc.).
///
/// Same three-tier scale as [BesoinEau] but kept as a distinct enum to avoid
/// semantic confusion in the model. See `docs/16-enrichissement-fiches-plantes.md` §H.
enum NiveauBesoin { faible, modere, eleve }
