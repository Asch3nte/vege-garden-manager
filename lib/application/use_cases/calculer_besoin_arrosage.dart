import 'package:riverpod/riverpod.dart';

import '../../domain/entities/plantation.dart';
import '../../domain/enums/type_releve_meteo.dart';
import '../../domain/exceptions/meteo_indisponible_exception.dart';
import '../../domain/extensions/date_calendaire.dart';
import '../../domain/repositories/abstract_equipement_repository.dart';
import '../../domain/repositories/abstract_fiche_plante_repository.dart';
import '../../domain/repositories/abstract_meteo_service.dart';
import '../../domain/repositories/abstract_parcelle_repository.dart';
import '../../domain/value_objects/conseil_arrosage.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/prevision_meteo.dart';
import '../engine/bilan_arrosage.dart';
import '../providers/horloge_provider.dart';
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
/// need to reason about). When the location is undefined, the weather is
/// unavailable offline, or the auto-fetch opt-out ([meteoAutoActive]) is off,
/// the advice is still produced from the plant + soil + equipment demand alone
/// (rain figures simply omitted).
class CalculerBesoinArrosage {
  final AbstractFichePlanteRepository _fiches;
  final AbstractParcelleRepository _parcelles;
  final AbstractEquipementRepository _equipements;
  final AbstractMeteoService _meteo;
  final BilanArrosage _bilan;

  final DateTime Function() _maintenant;

  CalculerBesoinArrosage(
    this._fiches,
    this._parcelles,
    this._equipements,
    this._meteo,
    this._bilan, {
    DateTime Function()? maintenant,
  }) : _maintenant = maintenant ?? DateTime.now;

  /// Loads the weather window ([joursRecents] past days + [joursFuturs]
  /// forecast days) used by [executer]. Empty when the location is undefined,
  /// the auto-fetch opt-out ([meteoAutoActive]) is off, or the weather is
  /// unavailable.
  Future<List<PrevisionMeteo>> chargerFenetre(
    Localisation localisation, {
    bool meteoAutoActive = true,
    int joursRecents = 5,
    int joursFuturs = 3,
  }) async {
    if (!localisation.estDefinie || !meteoAutoActive) return const [];
    try {
      return await _meteo.obtenirPrevisions(
        localisation,
        joursFuturs,
        joursPasses: joursRecents,
      );
    } on MeteoIndisponibleException {
      // Weather unavailable: the advice falls back to demand only.
      return const [];
    }
  }

  /// Computes the advice for [plantation]; [fenetre] is a window preloaded
  /// with [chargerFenetre], fetched here when absent.
  Future<ConseilArrosage?> executer({
    required Plantation plantation,
    required Localisation localisation,
    int joursRecents = 5,
    int joursFuturs = 3,
    bool meteoAutoActive = true,
    List<PrevisionMeteo>? fenetre,
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

    final meteo = fenetre ??
        await chargerFenetre(
          localisation,
          meteoAutoActive: meteoAutoActive,
          joursRecents: joursRecents,
          joursFuturs: joursFuturs,
        );

    double? pluieRecenteMm;
    double? pluiePrevueMm;
    int? joursAvantPluie;
    double probabilitePluiePrevu = 1.0;
    double? tempMax;
    double? et0Mm;
    if (meteo.isNotEmpty) {
      pluieRecenteMm = meteo
          .where((p) => p.type == TypeReleveMeteo.observe)
          .fold<double>(0, (acc, p) => acc + p.precipitationsMm);
      // Offsets come from the dates: a cached window may miss a day.
      final aujourdhui = _maintenant();
      final futur = meteo
          .where((p) =>
              p.type == TypeReleveMeteo.prevu &&
              aujourdhui.joursJusqua(p.date) >= 0)
          .toList(growable: false)
        ..sort((a, b) => a.date.compareTo(b.date));
      // Today's forecast tempMax and ET₀ drive the watering factor.
      final duJour = futur
          .where((p) => aujourdhui.joursJusqua(p.date) == 0)
          .firstOrNull;
      tempMax = duJour?.tempMax;
      et0Mm = duJour?.evapotranspirationMm;
      for (final jour in futur) {
        final score = jour.precipitationsMm * jour.probabilitePluie;
        if (score >= BilanArrosage.seuilScorePluie) {
          pluiePrevueMm = jour.precipitationsMm;
          probabilitePluiePrevu = jour.probabilitePluie;
          joursAvantPluie = aujourdhui.joursJusqua(jour.date);
          break;
        }
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
      probabilitePluiePrevu: probabilitePluiePrevu,
      tempMax: tempMax,
      et0Mm: et0Mm,
      toleranceSecheresse: fiche.toleranceSecheresse,
      temperatureMaxTolerance: fiche.temperatureMaxTolerance,
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
    maintenant: ref.watch(horlogeProvider),
  ),
);
