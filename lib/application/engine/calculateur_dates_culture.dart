import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/enums/stade_croissance.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/extensions/date_calendaire.dart';
import '../../domain/value_objects/estimation_recolte.dart';
import '../../domain/value_objects/etat_croissance.dart';
import '../../domain/value_objects/periodes_culture.dart';

/// Pure engine calculator for cultivation dates.
///
/// Stateless and dependency-free: it composes domain data only, so it is fully
/// testable without Riverpod, the database or the network. It carries the rule
/// `Plantation.dateRecolteEstimee(...)` that the entity deliberately defers
/// (it needs the [FichePlante], which the entity does not hold).
class CalculateurDatesCulture {
  const CalculateurDatesCulture();

  /// Fraction of the days-to-harvest below which a sown crop is still emerging.
  static const double _seuilLevee = 0.12;

  /// Fraction of the days-to-harvest above which a crop is maturing rather than
  /// in plain vegetative growth.
  static const double _seuilMaturation = 0.66;

  /// Estimated harvest window: planting date + the plant's min/max
  /// days-to-harvest. Pure arithmetic — does **not** depend on hemisphere or
  /// climate, so it is always available.
  EstimationRecolte estimerRecolte(Plantation plantation, FichePlante fiche) {
    return EstimationRecolte(
      dateMin:
          plantation.dateMiseEnPlace.plusJours(fiche.dureeAvantRecolteJoursMin),
      dateMax:
          plantation.dateMiseEnPlace.plusJours(fiche.dureeAvantRecolteJoursMax),
    );
  }

  /// The plantation's growth state at [reference]: current [StadeCroissance] and
  /// a progression in `[0, 1]`.
  ///
  /// Pure arithmetic over [Plantation.dateMiseEnPlace] and the plant's
  /// days-to-harvest — independent of hemisphere/climate, so always available.
  /// Progression is elapsed days / minimum days-to-harvest, clamped; a coarse,
  /// plant-agnostic curve (see [StadeCroissance]). Methods that establish an
  /// already-emerged plant (transplant, bought plant, cutting, division) skip the
  /// [StadeCroissance.levee] stage. A reference before planting reads as age 0.
  EtatCroissance etatCroissance(
    Plantation plantation,
    FichePlante fiche,
    DateTime reference,
  ) {
    final jours = plantation.dateMiseEnPlace.joursJusqua(reference);
    final age = jours < 0 ? 0 : jours;
    final fraction = age / fiche.dureeAvantRecolteJoursMin;

    final StadeCroissance stade;
    if (fraction >= 1.0) {
      stade = StadeCroissance.recolte;
    } else if (fraction >= _seuilMaturation) {
      stade = StadeCroissance.maturation;
    } else if (_commenceParLevee(plantation.methode) && fraction < _seuilLevee) {
      stade = StadeCroissance.levee;
    } else {
      stade = StadeCroissance.croissance;
    }

    return EtatCroissance(stade: stade, progression: fraction);
  }

  /// Whether [methode] starts from seed, and thus has an emergence phase.
  bool _commenceParLevee(MethodeMiseEnPlace methode) =>
      methode == MethodeMiseEnPlace.semisDirect ||
      methode == MethodeMiseEnPlace.semisInterieur;

  /// The sowing/planting/harvest month windows for a plant in a given
  /// [hemisphere] and [climat], or `null` when the catalogue has no data for
  /// that pair.
  PeriodesCulture? fenetresPour(
    FichePlante fiche,
    Hemisphere hemisphere,
    TypeClimat climat,
  ) =>
      fiche.periodesPour(hemisphere, climat);
}

/// DI provider for the (stateless) [CalculateurDatesCulture].
final calculateurDatesCultureProvider = Provider<CalculateurDatesCulture>(
  (ref) => const CalculateurDatesCulture(),
);
