import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/qualite_sol.dart';
import '../../domain/enums/raison_reco.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../domain/enums/zone_rusticite.dart';
import '../../domain/value_objects/recommandation_plante.dart';
import '../../domain/value_objects/surface.dart';

/// Pure engine calculator that evaluates **one** candidate plant for a parcelle.
///
/// Hard filters exclude unsuitable candidates (returns `null`); the survivors
/// get a soft score in `0..1` with the structured reasons behind it. The
/// orchestrating use case loops the catalogue, drops the nulls and ranks the
/// rest. Stateless and dependency-free.
///
/// ## Hard filters (exclusion)
/// 1. Season: not plantable this month (only when climate is known).
/// 2. Surface: not enough free room (espacement² vs free surface).
/// 3. Rotation conflict (computed by the caller, type-aware).
/// 4. Hard companion conflict (negative association already in the parcelle).
/// 5. Rusticité §A: potager's zone colder than the plant's minimum.
/// 6. Difficulty §C: plant too hard for the user's experience level.
/// 7. Container §D: plant incompatible with pot/planter type.
///
/// ## Soft score
/// Exposition (40%), soil quality (40%), beneficial companion (20%). Bonus
/// reasons (no weight change): [RaisonReco.cultureVerticaleCompatible].
///
/// See `docs/16-enrichissement-fiches-plantes.md` for the enrichment rationale.
class EvaluateurRecommandations {
  const EvaluateurRecommandations();

  static const double _poidsExposition = 0.4;
  static const double _poidsSol = 0.4;
  static const double _poidsAssociation = 0.2;

  /// Container types whose renewable soil relaxes rotation but which also
  /// constrain [FichePlante.compatibleHorsSol].
  static const Set<TypeParcelle> _typesSansRacines = {
    TypeParcelle.pot,
    TypeParcelle.jardiniere,
  };

  /// Maximum difficulty level accepted per [NiveauExperience].
  static int _difficulteMax(NiveauExperience niveau) => niveau.index + 1;

  /// Evaluates [candidate] in the parcelle context. Returns `null` when a hard
  /// filter excludes it.
  ///
  /// **Existing params** — [hemisphere]/[climat] are `null` when the user's
  /// climate is unknown: the season filter is then skipped. [rotationConflit]
  /// is `true` when the same family was grown too recently; [rotationVerifiee]
  /// is `true` when rotation was actually checked.
  ///
  /// **New params (all optional, backward-compatible)**:
  /// - [zoneRusticite]: potager's USDA hardiness zone — enables filter §A.
  /// - [niveauExperience]: user's experience level — enables filter §C.
  /// - [typeParcelle]: parcelle structure — enables filter §D.
  /// - [cultureVerticaleDisponible]: `true` when the parcelle has a trellis or
  ///   stake — triggers [RaisonReco.cultureVerticaleCompatible].
  RecommandationPlante? evaluer({
    required FichePlante candidate,
    required DateTime date,
    Hemisphere? hemisphere,
    TypeClimat? climat,
    required NiveauSoleil exposition,
    required Set<QualiteSol> qualitesSol,
    required Surface surfaceLibre,
    required Set<String> planteIdsActifs,
    required bool rotationConflit,
    required bool rotationVerifiee,
    ZoneRusticite? zoneRusticite,
    NiveauExperience? niveauExperience,
    TypeParcelle? typeParcelle,
    bool cultureVerticaleDisponible = false,
  }) {
    final saisonVerifiable = hemisphere != null && climat != null;

    // --- Hard filters -------------------------------------------------------

    // 1. Season
    if (saisonVerifiable &&
        !candidate.estPlantableEn(date, hemisphere, climat)) {
      return null;
    }
    // 2. Surface
    if (surfaceLibre.enMetresCarres < _surfaceParPlantM2(candidate)) {
      return null;
    }
    // 3. Rotation conflict
    if (rotationConflit) return null;
    // 4. Companion conflict
    if (planteIdsActifs.any(candidate.entreEnConflitAvec)) return null;
    // 5. Rusticité §A
    if (zoneRusticite != null && candidate.rusticiteMin != null &&
        zoneRusticite.numero < candidate.rusticiteMin!.numero) {
      return null;
    }
    // 6. Difficulty §C
    if (niveauExperience != null && candidate.difficulte != null &&
        candidate.difficulte! > _difficulteMax(niveauExperience)) {
      return null;
    }
    // 7. Container §D
    if (typeParcelle != null &&
        _typesSansRacines.contains(typeParcelle) &&
        !candidate.compatibleHorsSol) {
      return null;
    }

    // --- Soft score ---------------------------------------------------------
    final scoreExposition = _scoreExposition(
      candidate.besoins.soleil,
      candidate.besoins.soleilMin,
      exposition,
    );
    final scoreSol = _scoreSol(candidate.besoins.qualitesSol, qualitesSol);
    final associationBenefique =
        planteIdsActifs.any(candidate.sAssocieBienAvec);
    final scoreAssociation = associationBenefique ? 1.0 : 0.5;

    final score = (_poidsExposition * scoreExposition +
            _poidsSol * scoreSol +
            _poidsAssociation * scoreAssociation)
        .clamp(0.0, 1.0)
        .toDouble();

    final cultureVerticaleCompatible =
        candidate.cultureVerticale && cultureVerticaleDisponible;

    final raisons = <RaisonReco>{
      if (saisonVerifiable) RaisonReco.plantableMaintenant,
      if (scoreExposition >= 0.5) RaisonReco.expositionAdaptee,
      if (scoreSol >= 0.5) RaisonReco.solAdapte,
      if (associationBenefique) RaisonReco.bonneAssociation,
      if (rotationVerifiee && !rotationConflit) RaisonReco.rotationFavorable,
      if (niveauExperience != null && candidate.difficulte != null &&
          candidate.difficulte! <= _difficulteMax(niveauExperience))
        RaisonReco.niveauAdapte,
      if (cultureVerticaleCompatible) RaisonReco.cultureVerticaleCompatible,
    };

    return RecommandationPlante(
      planteId: candidate.id,
      score: score,
      raisons: raisons,
    );
  }

  /// Approximate ground area one plant needs: a square of side `espacementCm`.
  double _surfaceParPlantM2(FichePlante fiche) {
    final cote = fiche.espacementCm / 100;
    return cote * cote;
  }

  /// Sun score taking into account the optional [soleilMin] tolerance range.
  ///
  /// NiveauSoleil index: pleinSoleil=0 (most sun) … ombre=2 (least sun).
  /// - Perfect match ([parcelle] == [prefere]): 1.0.
  /// - Within tolerance ([prefere].index ≤ [parcelle].index ≤ [soleilMin].index):
  ///   0.5 (enough sun but suboptimal).
  /// - Below minimum tolerance (too shady): 0.0.
  /// - Above preferred (too sunny) or no [soleilMin]: distance-based fallback.
  double _scoreExposition(
    NiveauSoleil prefere,
    NiveauSoleil? soleilMin,
    NiveauSoleil parcelle,
  ) {
    if (parcelle == prefere) return 1.0;

    if (soleilMin != null) {
      // parcelle.index in [prefere.index .. soleilMin.index] → within tolerance
      if (parcelle.index > prefere.index &&
          parcelle.index <= soleilMin.index) {
        return 0.5;
      }
      // parcelle.index > soleilMin.index → too shady
      if (parcelle.index > soleilMin.index) return 0.0;
    }

    // Fallback: distance-based (original behaviour, also covers "too sunny")
    final distance = (prefere.index - parcelle.index).abs();
    return switch (distance) {
      0 => 1.0,
      1 => 0.5,
      _ => 0.0,
    };
  }

  /// Fraction of the plant's required soil qualities the parcelle offers.
  /// Neutral (1.0) when the plant states no soil requirement.
  double _scoreSol(Set<QualiteSol> requises, Set<QualiteSol> offertes) {
    if (requises.isEmpty) return 1.0;
    final satisfaites = requises.where(offertes.contains).length;
    return satisfaites / requises.length;
  }
}

/// DI provider for the (stateless) [EvaluateurRecommandations].
final evaluateurRecommandationsProvider = Provider<EvaluateurRecommandations>(
  (ref) => const EvaluateurRecommandations(),
);
