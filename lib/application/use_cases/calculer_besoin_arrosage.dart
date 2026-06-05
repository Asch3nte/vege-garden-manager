import 'package:riverpod/riverpod.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/enums/type_releve_meteo.dart';
import '../../domain/exceptions/meteo_indisponible_exception.dart';
import '../../domain/repositories/abstract_equipement_repository.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/value_objects/conseil_arrosage.dart';
import '../../domain/value_objects/localisation.dart';
import '../engine/bilan_arrosage.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';

/// Engine use case: compute the watering advice for a plantation.
///
/// Gathers every input the balance needs — the plant's water need (fiche), the
/// parcelle's soil texture and techniques, its in-service equipment (oya,
/// drip…), recent precipitation (past days) and the forecast — then delegates to
/// [BilanArrosage].
///
/// Returns `null` only when the plant is absent from the catalogue (no water
/// need to reason about). When the location is undefined or the weather is
/// unavailable offline, the advice is still produced from the plant + soil +
/// equipment demand alone (rain figures simply omitted).
class CalculerBesoinArrosage {
  final AbstractFichePlanteRepository _fiches;
  final AbstractParcelleRepository _parcelles;
  final AbstractEquipementRepository _equipements;
  final AbstractMeteoService _meteo;
  final BilanArrosage _bilan;

  CalculerBesoinArrosage(
    this._fiches,
    this._parcelles,
    this._equipements,
    this._meteo,
    this._bilan,
  );

  Future<ConseilArrosage?> executer({
    required Plantation plantation,
    required Localisation localisation,
    int joursRecents = 5,
    int joursFuturs = 3,
  }) async {
    final fiche = await _fiches.obtenirParId(plantation.planteId);
    if (fiche == null) return null;

    final parcelle = await _parcelles.obtenirParId(plantation.parcelleId);
    final equipements =
        await _equipements.obtenirParParcelle(plantation.parcelleId);
    final modificateurEquipement = equipements
        .where((e) => e.estEnService)
        .map((e) => e.effet().modificateurBesoinEau)
        .fold<double>(1.0, (acc, m) => acc * m);

    double? pluieRecenteMm;
    double? pluiePrevueMm;
    int? joursAvantPluie;
    if (localisation.estDefinie) {
      try {
        final fenetre = await _meteo.obtenirPrevisions(
          localisation,
          joursFuturs,
          joursPasses: joursRecents,
        );
        pluieRecenteMm = fenetre
            .where((p) => p.type == TypeReleveMeteo.observe)
            .fold<double>(0, (acc, p) => acc + p.precipitationsMm);
        final futur = fenetre
            .where((p) => p.type == TypeReleveMeteo.prevu)
            .toList(growable: false);
        for (var i = 0; i < futur.length; i++) {
          if (futur[i].precipitationsMm >= BilanArrosage.seuilPluiePrevueMm) {
            pluiePrevueMm = futur[i].precipitationsMm;
            joursAvantPluie = i; // forecast starts today (offset 0)
            break;
          }
        }
      } on MeteoIndisponibleException {
        // Weather unavailable: fall back to the demand-only advice.
      }
    }

    return _bilan.calculer(
      besoinEau: fiche.besoins.eau,
      texture: parcelle?.texture,
      techniques: parcelle?.techniquesSol ?? const {},
      modificateurEquipement: modificateurEquipement,
      pluieRecenteMm: pluieRecenteMm,
      pluiePrevueMm: pluiePrevueMm,
      joursAvantPluie: joursAvantPluie,
    );
  }
}

/// DI provider for [CalculerBesoinArrosage]. Async because the catalogue
/// repository is loaded from YAML assets.
final calculerBesoinArrosageProvider =
    FutureProvider<CalculerBesoinArrosage>(
  (ref) async => CalculerBesoinArrosage(
    await ref.watch(fichePlanteRepositoryProvider.future),
    ref.watch(parcelleRepositoryProvider),
    ref.watch(equipementRepositoryProvider),
    ref.watch(meteoServiceProvider),
    ref.watch(bilanArrosageProvider),
  ),
);
