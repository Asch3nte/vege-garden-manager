import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/niveau_soleil.dart';
import '../../domain/enums/qualite_sol.dart';
import '../../domain/enums/raison_reco.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/value_objects/recommandation_plante.dart';
import '../../domain/value_objects/surface.dart';

/// Pure engine calculator that evaluates **one** candidate plant for a parcelle.
///
/// Hard filters exclude unsuitable candidates (returns `null`); the survivors
/// get a soft score in `0..1` with the structured reasons behind it. The
/// orchestrating use case loops the catalogue, drops the nulls and ranks the
/// rest. Stateless and dependency-free.
///
/// Hard filters: not plantable this season (only when the climate is known),
/// not enough free room (espacement vs free surface), crop-rotation conflict
/// (computed by the caller, type-aware), or a hard companion conflict.
///
/// Soft score: sun-exposure match (0.4), soil-quality match (0.4), beneficial
/// companion present (0.2). Provisional V1 weights.
class EvaluateurRecommandations {
  const EvaluateurRecommandations();

  static const double _poidsExposition = 0.4;
  static const double _poidsSol = 0.4;
  static const double _poidsAssociation = 0.2;

  /// Evaluates [candidate] in the parcelle context. Returns `null` when a hard
  /// filter excludes it.
  ///
  /// [hemisphere]/[climat] are `null` when the user's climate is unknown: the
  /// season filter is then skipped (the caller flags `saisonNonVerifiee`).
  /// [rotationConflit] is `true` when the same family was grown too recently in
  /// this (soil-persistent) parcelle; [rotationVerifiee] is `true` when rotation
  /// was actually checked (false for renewable containers).
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
  }) {
    final saisonVerifiable = hemisphere != null && climat != null;

    // --- Hard filters -------------------------------------------------------
    if (saisonVerifiable &&
        !candidate.estPlantableEn(date, hemisphere, climat)) {
      return null;
    }
    if (surfaceLibre.enMetresCarres < _surfaceParPlantM2(candidate)) {
      return null;
    }
    if (rotationConflit) return null;
    if (planteIdsActifs.any(candidate.entreEnConflitAvec)) return null;

    // --- Soft score ---------------------------------------------------------
    final scoreExposition = _scoreExposition(candidate.besoins.soleil, exposition);
    final scoreSol = _scoreSol(candidate.besoins.qualitesSol, qualitesSol);
    final associationBenefique =
        planteIdsActifs.any(candidate.sAssocieBienAvec);
    final scoreAssociation = associationBenefique ? 1.0 : 0.5;

    final score = (_poidsExposition * scoreExposition +
            _poidsSol * scoreSol +
            _poidsAssociation * scoreAssociation)
        .clamp(0.0, 1.0)
        .toDouble();

    final raisons = <RaisonReco>{
      if (saisonVerifiable) RaisonReco.plantableMaintenant,
      if (scoreExposition >= 0.5) RaisonReco.expositionAdaptee,
      if (scoreSol >= 0.5) RaisonReco.solAdapte,
      if (associationBenefique) RaisonReco.bonneAssociation,
      if (rotationVerifiee && !rotationConflit) RaisonReco.rotationFavorable,
    };

    return RecommandationPlante(
      planteId: candidate.id,
      score: score,
      raisons: raisons,
    );
  }

  /// Approximate ground area one plant needs: a square of side `espacementCm`.
  double _surfaceParPlantM2(FichePlante fiche) {
    final cote = fiche.espacementCm / 100; // metres
    return cote * cote;
  }

  /// 1.0 for an exact sun match, 0.5 for one level off, 0.0 for two levels off.
  double _scoreExposition(NiveauSoleil besoin, NiveauSoleil parcelle) {
    final distance = (besoin.index - parcelle.index).abs();
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
