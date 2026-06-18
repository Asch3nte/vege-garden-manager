import '../../domain/value_objects/prevision_horaire.dart';

/// Aggregated daily weather view-model, combining one [PrevisionMeteo] (daily
/// summary) with the subset of [PrevisionHoraire] for that calendar day.
///
/// [risqueGel] / [risqueCanicule] are derived from [tempMin] / [tempMax]
/// against [SeuilsMeteo] thresholds at construction time by
/// [MeteoDetailNotifier]. [ventMaxKmh] is the highest hourly wind speed of
/// the day (0 when no hourly data is available). See ADR-0016 Lot 3.
class JourMeteoVue {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double precipitationsMm;

  /// Probability of rain for the day (0..1).
  final double probabilitePluie;

  /// WMO weather interpretation code (0–99; 0 = clear sky).
  final int weathercode;

  final bool risqueGel;
  final bool risqueCanicule;

  /// Maximum wind speed over the day's hourly records (km/h).
  final double ventMaxKmh;

  /// Hourly forecasts for this calendar day, ordered by hour.
  final List<PrevisionHoraire> heures;

  const JourMeteoVue({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.precipitationsMm,
    required this.probabilitePluie,
    required this.weathercode,
    required this.risqueGel,
    required this.risqueCanicule,
    required this.ventMaxKmh,
    required this.heures,
  });
}
