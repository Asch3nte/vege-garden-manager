import '../../domain/enums/qualite_sol.dart';
import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/texture_sol.dart';

/// Pure engine helper deriving soil water-retention factors from a parcelle's
/// texture and cultivation techniques.
///
/// Factors are **multipliers on the watering demand** (1.0 = neutral, `< 1`
/// retains water so waters less often, `> 1` drains so waters more often). The
/// values are **provisional V1 heuristics**, documented and calibratable.
class DerivationSol {
  const DerivationSol();

  /// Demand multiplier by soil texture (drains → > 1, retains → < 1). Unknown
  /// texture is neutral.
  static const Map<TextureSol, double> _facteurTexture = {
    TextureSol.argileux: 0.75,
    TextureSol.humifere: 0.75,
    TextureSol.tourbeux: 0.70,
    TextureSol.limoneux: 1.0,
    TextureSol.calcaire: 1.0,
    TextureSol.sableux: 1.30,
    TextureSol.caillouteux: 1.30,
  };

  /// Techniques that noticeably retain soil water (mulches, water-storing beds,
  /// water-harvesting earthworks).
  static const Set<TechniqueSol> techniquesRetentrices = {
    TechniqueSol.paillage,
    TechniqueSol.brf,
    TechniqueSol.mulchVivant,
    TechniqueSol.engraisVertCouvert,
    TechniqueSol.paillageMineral,
    TechniqueSol.carton,
    TechniqueSol.mulchDeFoin,
    TechniqueSol.hugelkultur,
    TechniqueSol.butteLasagne,
    TechniqueSol.swales,
    TechniqueSol.keylineDesign,
  };

  /// Demand multiplier applied when at least one retaining technique is present.
  static const double facteurTechniqueRetentrice = 0.7;

  double facteurTexture(TextureSol? texture) =>
      texture == null ? 1.0 : _facteurTexture[texture] ?? 1.0;

  /// `0.7` when any retaining technique is present, else `1.0`. The strongest
  /// single effect is taken (not stacked) to avoid over-reducing the demand.
  double facteurTechniques(Set<TechniqueSol> techniques) =>
      techniques.any(techniquesRetentrices.contains)
          ? facteurTechniqueRetentrice
          : 1.0;

  /// Base soil qualities derived from the texture (provisional heuristic).
  static const Map<TextureSol, Set<QualiteSol>> _qualitesTexture = {
    TextureSol.argileux: {QualiteSol.lourd, QualiteSol.riche, QualiteSol.malDraine},
    TextureSol.sableux: {QualiteSol.leger, QualiteSol.bienDraine, QualiteSol.sec},
    TextureSol.limoneux: {QualiteSol.riche, QualiteSol.frais, QualiteSol.bienDraine},
    TextureSol.calcaire: {QualiteSol.leger, QualiteSol.sec, QualiteSol.pauvre},
    TextureSol.humifere: {QualiteSol.riche, QualiteSol.frais},
    TextureSol.tourbeux: {QualiteSol.riche, QualiteSol.frais, QualiteSol.malDraine},
    TextureSol.caillouteux: {
      QualiteSol.leger,
      QualiteSol.bienDraine,
      QualiteSol.sec,
      QualiteSol.pauvre,
    },
  };

  /// Techniques that enrich the soil → adds [QualiteSol.riche].
  static const Set<TechniqueSol> _techniquesEnrichissantes = {
    TechniqueSol.compostageSurface,
    TechniqueSol.compostEnTrou,
    TechniqueSol.bokashi,
    TechniqueSol.brf,
    TechniqueSol.mulchVivant,
    TechniqueSol.butteLasagne,
    TechniqueSol.hugelkultur,
    TechniqueSol.engraisVertCouvert,
  };

  /// Techniques that keep the soil cool/moist → adds [QualiteSol.frais].
  static const Set<TechniqueSol> _techniquesRafraichissantes = {
    TechniqueSol.paillage,
    TechniqueSol.paillageMineral,
    TechniqueSol.carton,
    TechniqueSol.mulchDeFoin,
    TechniqueSol.mulchVivant,
  };

  /// Techniques that improve drainage/structure → adds [QualiteSol.bienDraine].
  static const Set<TechniqueSol> _techniquesDrainantes = {
    TechniqueSol.butteRonde,
    TechniqueSol.buttePermanente,
    TechniqueSol.hugelkultur,
    TechniqueSol.noDig,
  };

  /// Derives the soil qualities a parcelle offers, from its [texture] and the
  /// [techniques] in use. The result feeds the plant/soil match in
  /// recommendations. Provisional V1 heuristic — empty when the texture is
  /// unknown and no enriching technique applies.
  Set<QualiteSol> qualitesDe(
    TextureSol? texture,
    Set<TechniqueSol> techniques,
  ) {
    final qualites = <QualiteSol>{
      if (texture != null) ..._qualitesTexture[texture] ?? const {},
    };
    if (techniques.any(_techniquesEnrichissantes.contains)) {
      qualites.add(QualiteSol.riche);
    }
    if (techniques.any(_techniquesRafraichissantes.contains)) {
      qualites.add(QualiteSol.frais);
    }
    if (techniques.any(_techniquesDrainantes.contains)) {
      qualites.add(QualiteSol.bienDraine);
    }
    return Set.unmodifiable(qualites);
  }
}
