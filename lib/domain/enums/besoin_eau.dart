/// Qualitative water need of a plant.
///
/// Represents a *level* of need (not a frequency): the engine combines it with
/// weather and soil to decide watering. See `docs/05-modele-de-domaine.md` §5.
enum BesoinEau { faible, modere, eleve }
