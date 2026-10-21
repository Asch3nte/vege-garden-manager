/// Soil qualities a plant looks for (the "desired" side of soil).
///
/// Distinct from the texture a parcelle *has* (`TextureSol`): the engine derives
/// qualities from a texture via a correspondence table.
enum QualiteSol { riche, pauvre, bienDraine, malDraine, frais, sec, lourd, leger }
