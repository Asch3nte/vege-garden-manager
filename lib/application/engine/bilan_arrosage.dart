import 'package:riverpod/riverpod.dart';

import '../../domain/enums/besoin_eau.dart';
import '../../domain/enums/technique_sol.dart';
import '../../domain/enums/texture_sol.dart';
import '../../domain/enums/urgence_arrosage.dart';
import '../../domain/value_objects/conseil_arrosage.dart';
import 'derivation_sol.dart';

/// Pure engine calculator for the watering balance.
///
/// Multiplicative heuristic (V1, provisional/calibratable): the plant's base
/// water demand is scaled by the soil texture, the cultivation techniques
/// (mulch…) and the equipment (oya, drip…), then arbitrated against recent and
/// forecast rain:
///
/// `indice = base(BesoinEau) × factTexture × factTechniques × modifEquipement`
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

  /// Demand index at/above which watering is needed now (high-need plants).
  static const double seuilArroserMaintenant = 0.7;

  /// Demand index at/above which watering is needed soon (moderate-need plants).
  static const double seuilBientot = 0.4;

  /// Default delay (days) attached to a "soon" advice.
  static const int joursAvantArrosageBientot = 2;

  /// Computes the watering advice. Rain figures are optional: when the weather
  /// is unknown (location opt-out or offline) the advice rests on the plant +
  /// soil + equipment demand alone.
  ConseilArrosage calculer({
    required BesoinEau besoinEau,
    TextureSol? texture,
    Set<TechniqueSol> techniques = const {},
    double modificateurEquipement = 1.0,
    double? pluieRecenteMm,
    double? pluiePrevueMm,
    int? joursAvantPluie,
  }) {
    final factTexture = _sol.facteurTexture(texture);
    final factTechniques = _sol.facteurTechniques(techniques);
    final indice = (baseDemande[besoinEau]! *
            factTexture *
            factTechniques *
            modificateurEquipement)
        .clamp(0.0, 1.0)
        .toDouble();
    final retentionRenforcee =
        factTexture < 1 || factTechniques < 1 || modificateurEquipement < 1;
    final pluieRecente =
        pluieRecenteMm != null && pluieRecenteMm >= seuilPluieRecenteMm;
    final pluiePrevue =
        pluiePrevueMm != null && pluiePrevueMm >= seuilPluiePrevueMm;

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
