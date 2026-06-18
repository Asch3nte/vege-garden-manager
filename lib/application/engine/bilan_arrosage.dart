import 'package:riverpod/riverpod.dart';

import '../../core/constants/constantes_moteur.dart';
import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/texture_sol.dart';
import '../../domain/enums/tolerance_secheresse.dart';
import '../../domain/enums/urgence_arrosage.dart';
import '../../domain/value_objects/conseil_arrosage.dart';
import 'derivation_sol.dart';

/// Pure engine calculator for the watering balance.
///
/// Multiplicative heuristic (V1, calibratable — see ADR-0015): the plant's
/// base water demand is scaled by soil texture, cultivation techniques
/// (mulch…), equipment (oya, drip…), and a **temperature factor** (ET₀ proxy),
/// then arbitrated against recent and forecast rain:
///
/// `indice = base(BesoinEau) × factTexture × factTechniques × factEquipement
///           × factTemperature`
///
/// Decision: forecast rain → defer; otherwise recent rain → no need; otherwise
/// the demand index maps to *water now / soon / not needed*.
class BilanArrosage {
  final DerivationSol _sol;

  const BilanArrosage([this._sol = const DerivationSol()]);

  /// Base demand by water need (0..1).
  static const Map<BesoinEau, double> baseDemande = {
    BesoinEau.faible: 0.35,
    BesoinEau.modere: 0.65,
    BesoinEau.eleve: 1.0,
  };

  /// Recent precipitation (summed over the past window, mm) at/above which the
  /// soil is considered still moist.
  static const double seuilPluieRecenteMm = 15;

  /// A forecast day's precipitation (mm) at/above which watering is deferred.
  static const double seuilPluiePrevueMm = 10;

  /// Minimum weighted rain score (mm × probability) to defer watering.
  ///
  /// ≈ 10 mm × 60 % or 8 mm × 75 %
  static const double seuilScorePluie = 6.0;

  /// Demand index at/above which watering is needed now (high-need plants).
  static const double seuilArroserMaintenant = 0.7;

  /// Demand index at/above which watering is needed soon (moderate-need plants).
  static const double seuilBientot = 0.4;

  /// Default delay (days) attached to a "soon" advice.
  static const int joursAvantArrosageBientot = 2;

  // --- Temperature factor thresholds (ADR-0015 Décision 1) ---

  /// tempMax (°C) at which evapotranspiration starts to noticeably increase.
  static const double seuilTempChaudeC = 25.0;

  /// tempMax (°C) above which heat is significant (ET₀ ~40 % higher).
  static const double seuilTempTresChaudeC = 30.0;

  // Note: heatwave threshold reuses [SeuilsMeteo.caniculeC] (35 °C).

  /// Demand multiplier for warm days (25–29 °C).
  static const double facteurTempChaud = 1.2;

  /// Demand multiplier for hot days (30–34 °C).
  static const double facteurTempTresChaud = 1.4;

  /// Demand multiplier for heatwave days (≥ 35 °C).
  static const double facteurTempCanicule = 1.7;

  /// Returns the temperature multiplier for [tempMax] (°C), a proxy for
  /// evapotranspiration (ET₀). Returns 1.0 when [tempMax] is null (weather
  /// unknown: conservative — never silently wrong).
  static double facteurTemperature(double? tempMax) {
    if (tempMax == null) return 1.0;
    if (tempMax >= SeuilsMeteo.caniculeC) return facteurTempCanicule;
    if (tempMax >= seuilTempTresChaudeC) return facteurTempTresChaud;
    if (tempMax >= seuilTempChaudeC) return facteurTempChaud;
    return 1.0;
  }

  // --- ET₀ & per-plant factors (ADR-0015 Décisions 4 & 5) ---

  /// Reference ET₀ (mm/day) for a typical temperate summer day.
  static const double referenceET0Mm = 5.0;

  /// Drought-tolerance demand multipliers (ADR-0015 Décision 4).
  static const double facteurSecheresseFaible = 1.2;
  static const double facteurSecheresseForte = 0.8;

  /// Plant-specific temperature override: if [tempMax] exceeds the plant's
  /// [temperatureMaxTolerance], the heatwave factor is applied regardless of
  /// the generic tier (ADR-0015 Décision 4).
  static double _facteurTemperatureEffectif(
      double? tempMax, double? temperatureMaxTolerance) {
    if (tempMax == null) return 1.0;
    if (temperatureMaxTolerance != null &&
        tempMax >= temperatureMaxTolerance) {
      return facteurTempCanicule;
    }
    return facteurTemperature(tempMax);
  }

  /// ET₀-based demand factor: replaces the temperature heuristic when ET₀
  /// data is available from Open-Meteo (ADR-0015 Décision 5).
  /// [et0Mm] is the reference evapotranspiration in mm/day.
  static double facteurET0(double et0Mm) =>
      (et0Mm / referenceET0Mm).clamp(0.5, 2.5);

  static double _facteurToleranceSecheresse(
          ToleranceSecheresse? tolerance) =>
      switch (tolerance) {
        ToleranceSecheresse.faible => facteurSecheresseFaible,
        ToleranceSecheresse.forte => facteurSecheresseForte,
        _ => 1.0,
      };

  /// Computes the watering advice. Rain figures and [tempMax] are optional:
  /// when the weather is unknown (location opt-out or offline) the advice rests
  /// on the plant + soil + equipment demand alone (temperature factor = 1.0).
  ConseilArrosage calculer({
    required BesoinEau besoinEau,
    TextureSol? texture,
    Set<TechniqueSol> techniques = const {},
    double modificateurEquipement = 1.0,
    double? pluieRecenteMm,
    double? pluiePrevueMm,
    int? joursAvantPluie,
    double probabilitePluiePrevu = 1.0,
    double? tempMax,
    double? et0Mm,
    ToleranceSecheresse? toleranceSecheresse,
    double? temperatureMaxTolerance,
  }) {
    final factTexture = _sol.facteurTexture(texture);
    final factTechniques = _sol.facteurTechniques(techniques);
    final factTemp = et0Mm != null
        ? facteurET0(et0Mm)
        : _facteurTemperatureEffectif(tempMax, temperatureMaxTolerance);
    final factTolerance = _facteurToleranceSecheresse(toleranceSecheresse);
    final indice = (baseDemande[besoinEau]! *
            factTexture *
            factTechniques *
            modificateurEquipement *
            factTemp *
            factTolerance)
        .clamp(0.0, 1.0)
        .toDouble();
    final retentionRenforcee =
        factTexture < 1 || factTechniques < 1 || modificateurEquipement < 1;
    final pluieRecente =
        pluieRecenteMm != null && pluieRecenteMm >= seuilPluieRecenteMm;
    final pluiePrevue = pluiePrevueMm != null &&
        (pluiePrevueMm * probabilitePluiePrevu) >= seuilScorePluie;

    final UrgenceArrosage urgence;
    final int? joursAvant;
    if (pluiePrevue) {
      urgence = UrgenceArrosage.pasNecessaire; // the rain will water it
      joursAvant = joursAvantPluie;
    } else if (pluieRecente) {
      urgence = UrgenceArrosage.pasNecessaire; // soil still moist
      joursAvant = null;
    } else if (indice >= seuilArroserMaintenant) {
      urgence = UrgenceArrosage.arroserMaintenant;
      joursAvant = 0;
    } else if (indice >= seuilBientot) {
      urgence = UrgenceArrosage.bientot;
      joursAvant = joursAvantArrosageBientot;
    } else {
      urgence = UrgenceArrosage.pasNecessaire; // low demand
      joursAvant = null;
    }

    return ConseilArrosage(
      urgence: urgence,
      joursAvantArrosage: joursAvant,
      pluieRecente: pluieRecente,
      pluiePrevue: pluiePrevue,
      retentionRenforcee: retentionRenforcee,
      indiceBesoin: indice,
    );
  }
}

/// DI provider for the (stateless) [BilanArrosage].
final bilanArrosageProvider = Provider<BilanArrosage>(
  (ref) => const BilanArrosage(),
);
