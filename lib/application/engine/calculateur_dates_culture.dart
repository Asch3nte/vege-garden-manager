import 'package:riverpod/riverpod.dart';

import '../../domain/entities/fiche_plante.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/enums/hemisphere.dart';
import '../../domain/enums/type_climat.dart';
import '../../domain/value_objects/estimation_recolte.dart';
import '../../domain/value_objects/localisation.dart';
import '../../domain/value_objects/periodes_culture.dart';

/// Pure engine calculator for cultivation dates.
///
/// Stateless and dependency-free: it composes domain data only, so it is fully
/// testable without Riverpod, the database or the network. It carries the rule
/// `Plantation.dateRecolteEstimee(...)` that the entity deliberately defers
/// (it needs the [FichePlante], which the entity does not hold).
class CalculateurDatesCulture {
  const CalculateurDatesCulture();

  /// Estimated harvest window: planting date + the plant's min/max
  /// days-to-harvest. Pure arithmetic — does **not** depend on hemisphere or
  /// climate, so it is always available.
  EstimationRecolte estimerRecolte(Plantation plantation, FichePlante fiche) {
    return EstimationRecolte(
      dateMin:
          _plusJours(plantation.dateMiseEnPlace, fiche.dureeAvantRecolteJoursMin),
      dateMax:
          _plusJours(plantation.dateMiseEnPlace, fiche.dureeAvantRecolteJoursMax),
    );
  }

  /// The sowing/planting/harvest month windows for a plant in a given
  /// [hemisphere] and [climat], or `null` when the catalogue has no data for
  /// that pair.
  PeriodesCulture? fenetresPour(
    FichePlante fiche,
    Hemisphere hemisphere,
    TypeClimat climat,
  ) =>
      fiche.periodesPour(hemisphere, climat);

  /// Derives the hemisphere from a location's latitude.
  ///
  /// Returns `null` when the latitude is unknown — the engine never invents a
  /// default. A defined location is expected to be obtained at onboarding (GPS
  /// or an approximate map pick); see the onboarding requirement.
  Hemisphere? hemisphereDe(Localisation localisation) {
    final latitude = localisation.latitude;
    if (latitude == null) return null;
    return latitude < 0 ? Hemisphere.sud : Hemisphere.nord;
  }

  /// Adds [jours] calendar days to [date] via the constructor (which normalises
  /// day overflow), staying DST-safe and preserving the date's UTC/local kind.
  DateTime _plusJours(DateTime date, int jours) => date.isUtc
      ? DateTime.utc(date.year, date.month, date.day + jours)
      : DateTime(date.year, date.month, date.day + jours);
}

/// DI provider for the (stateless) [CalculateurDatesCulture].
final calculateurDatesCultureProvider = Provider<CalculateurDatesCulture>(
  (ref) => const CalculateurDatesCulture(),
);
