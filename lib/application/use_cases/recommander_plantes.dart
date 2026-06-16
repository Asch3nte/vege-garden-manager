import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/entities/parcelle.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/niveau_experience.dart';
import '../../domain/enums/type_parcelle.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_plantation_repository.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/recommandation_plante.dart';
import '../../domain/value_objects/resultat_recommandations.dart';
import '../../domain/value_objects/surface.dart';
import '../../domain/value_objects/zone_climatique.dart';
import '../engine/derivation_sol.dart';
import '../engine/evaluateur_recommandations.dart';
import '../engine/moteur_derivation_associations.dart';
import '../engine/suggestion_association.dart';
import '../providers/repository_providers.dart';
import '../../domain/enums/niveau_confiance.dart';

/// Engine use case: recommend plants to grow in a parcelle.
///
/// Crosses season (climate + hemisphere), available room, soil match, companion
/// associations and crop rotation, then ranks the survivors by score. Delegates
/// the per-candidate scoring to [EvaluateurRecommandations] and the soil
/// derivation to [DerivationSol].
///
/// Rotation is **type-aware**: it is enforced on soil-persistent parcelles
/// (open ground, raised bed, greenhouse, mound) but **relaxed on renewable
/// containers** (pot, planter) — fresh potting soil resets the rotation clock.
/// (A future refinement would track an explicit soil-renewal event so a renewed
/// raised bed is also cleared, and a non-renewed pot still constrained.)
class RecommanderPlantes {
  final AbstractFichePlanteRepository _fiches;
  final AbstractPlantationRepository _plantations;
  final EvaluateurRecommandations _evaluateur;
  final DerivationSol _sol;
  final MoteurDerivationAssociations _associations;

  RecommanderPlantes(
    this._fiches,
    this._plantations,
    this._evaluateur, {
    this._sol = const DerivationSol(),
    this._associations = const MoteurDerivationAssociations(),
  });

  /// Default return delay (years) when a plant sheet states none.
  static const int delaiRetourDefautAnnees = 3;

  /// Container parcelle types whose soil is routinely renewed → rotation
  /// relaxed.
  static const Set<TypeParcelle> _typesSansRotation = {
    TypeParcelle.pot,
    TypeParcelle.jardiniere,
  };

  Future<ResultatRecommandations> executer({
    required Parcelle parcelle,
    required ZoneClimatique zoneClimatique,
    required Localisation localisation,
    DateTime? date,
    NiveauExperience? niveauExperience,
  }) async {
    final maintenant = date ?? DateTime.now();
    final hemisphere = _hemisphereDe(localisation);
    final climat = zoneClimatique.type;

    final catalogue = await _fiches.obtenirToutes();
    final parId = {for (final f in catalogue) f.id: f};

    final plantations = await _plantations.obtenirParParcelle(parcelle.id);
    final actives = plantations.where((p) => p.estActive()).toList();
    // Compare at the species level (ADR-0005): a planted variety resolves to its
    // mother id, so presence and companion checks match the candidates (mothers)
    // and their associations (declared by mother id).
    final planteIdsActifs =
        actives.map((p) => _mereDe(p.planteId, parId)).toSet();
    // Mother sheets of the active plants, for trait-based derived associations.
    final actifsFiches =
        planteIdsActifs.map((id) => parId[id]).whereType<FichePlante>().toList();
    final surfaceLibre = _surfaceLibre(parcelle, actives);
    final qualitesSol = _sol.qualitesDe(parcelle.texture, parcelle.techniquesSol);
    final rotationVerifiee = !_typesSansRotation.contains(parcelle.type);

    final recommandations = <RecommandationPlante>[];
    // The engine evaluates at the species level only: candidates are mother
    // sheets; varieties are never recommended directly (ADR-0005).
    for (final candidate in catalogue.where((f) => f.estMere)) {
      // Don't recommend a species already growing here (any of its varieties).
      if (planteIdsActifs.contains(candidate.id)) continue;

      final rotationConflit = rotationVerifiee &&
          _rotationConflit(candidate, plantations, parId, maintenant);

      // Derived beneficial association (ADR-0010): only when no curated good pair
      // already covers it, and only on a reasonably confident, trait-based rule
      // (no family resolver here → repulsion/trap are left out).
      final deriveBenefice =
          !planteIdsActifs.any(candidate.sAssocieBienAvec) &&
              actifsFiches.any((actif) => _benefDerive(candidate, actif));

      final reco = _evaluateur.evaluer(
        candidate: candidate,
        date: maintenant,
        hemisphere: hemisphere,
        climat: hemisphere == null ? null : climat,
        exposition: parcelle.exposition,
        qualitesSol: qualitesSol,
        surfaceLibre: surfaceLibre,
        planteIdsActifs: planteIdsActifs,
        rotationConflit: rotationConflit,
        rotationVerifiee: rotationVerifiee,
        zoneRusticite: zoneClimatique.rusticite,
        niveauExperience: niveauExperience,
        typeParcelle: parcelle.type,
        cultureVerticaleDisponible: parcelle.cultureVerticale,
        associationDeriveeFavorable: deriveBenefice,
      );
      if (reco != null) recommandations.add(reco);
    }

    recommandations.sort((a, b) => b.score.compareTo(a.score));
    return ResultatRecommandations(
      recommandations: recommandations,
      saisonNonVerifiee: hemisphere == null,
    );
  }

  Hemisphere? _hemisphereDe(Localisation loc) {
    final lat = loc.latitude;
    if (lat == null) return null;
    return lat < 0 ? Hemisphere.sud : Hemisphere.nord;
  }

  Surface _surfaceLibre(Parcelle parcelle, List<Plantation> actives) {
    final occupee = actives
        .map((p) => p.surfaceOccupee)
        .fold(Surface.zero, (total, s) => total + s);
    return occupee >= parcelle.surface
        ? Surface.zero
        : parcelle.surface - occupee;
  }

  /// Whether the candidate's botanical family was grown in this parcelle within
  /// its return delay (most recent culture of that family still too recent).
  bool _rotationConflit(
    FichePlante candidate,
    List<Plantation> plantations,
    Map<String, FichePlante> parId,
    DateTime maintenant,
  ) {
    final famille = _famille(candidate);
    final delai = candidate.delaiRetourAnnees ?? delaiRetourDefautAnnees;
    final seuil =
        DateTime(maintenant.year - delai, maintenant.month, maintenant.day);

    for (final p in plantations) {
      final fiche = parId[p.planteId];
      if (fiche == null || _famille(fiche) != famille) continue;
      final reference = p.dateFinReelle ?? p.dateMiseEnPlace;
      if (reference.isAfter(seuil)) return true; // grown too recently
    }
    return false;
  }

  /// Whether a confident (≥ moyen), trait-based beneficial association is
  /// derived between [candidate] and an active [actif] (either direction).
  bool _benefDerive(FichePlante candidate, FichePlante actif) {
    bool fort(SuggestionAssociation s) =>
        s is SuggestionBenefique &&
        s.confiance.index >= NiveauConfiance.moyen.index;
    return _associations.deriver(candidate, actif).any(fort) ||
        _associations.deriver(actif, candidate).any(fort);
  }

  String _famille(FichePlante fiche) =>
      fiche.rotationFamille ?? fiche.familleBotanique;

  /// Species (mother) id behind a plantation's [planteId]: the sheet's
  /// `parentId` when a variety was planted, otherwise [planteId] itself.
  String _mereDe(String planteId, Map<String, FichePlante> parId) =>
      parId[planteId]?.parentId ?? planteId;
}

/// DI provider for [RecommanderPlantes]. Async because the catalogue repository
/// is loaded from YAML assets.
final recommanderPlantesProvider = FutureProvider<RecommanderPlantes>(
  (ref) async => RecommanderPlantes(
    await ref.watch(fichePlanteRepositoryProvider.future),
    ref.watch(plantationRepositoryProvider),
    ref.watch(evaluateurRecommandationsProvider),
  ),
);
