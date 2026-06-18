import '../value_objects/donnees_meteo.dart';
import '../value_objects/localisation.dart';
import '../value_objects/prevision_horaire.dart';
import '../value_objects/prevision_meteo.dart';

/// Contract for fetching weather (implemented with Open-Meteo in the
/// infrastructure layer).
///
/// See `docs/05-modele-de-domaine.md` §7 and ADR-0016.
abstract class AbstractMeteoService {
  /// Current weather at [loc].
  Future<DonneesMeteo> obtenirMeteoActuelle(Localisation loc);

  /// Daily weather window at [loc]: the next [nbJours] forecast days, optionally
  /// preceded by [joursPasses] past days.
  ///
  /// The returned list is ordered by date. Past days carry
  /// `TypeReleveMeteo.observe`, forecast days `TypeReleveMeteo.prevu`. With the
  /// default [joursPasses] of 0, only the forecast is returned (the common case,
  /// e.g. weather alerts); the watering engine passes a non-zero [joursPasses]
  /// to also obtain recent precipitation.
  Future<List<PrevisionMeteo>> obtenirPrevisions(
    Localisation loc,
    int nbJours, {
    int joursPasses = 0,
  });

  /// Hourly forecast at [loc] over the next [nbJours] days, ordered by hour
  /// (for the weather detail view). Throws when [loc] has no coordinates or on
  /// any network/parse error.
  Future<List<PrevisionHoraire>> obtenirPrevisionsHoraires(
    Localisation loc, {
    int nbJours = 3,
  });

  /// Elevation (metres) at [loc] from the Open-Meteo response metadata, or
  /// `null` when the location is undefined or the service is unavailable.
  ///
  /// Never throws — callers treat `null` as "elevation unknown" and omit it
  /// from the display (ADR-0016 Lot 2).
  Future<double?> obtenirElevation(Localisation loc);
}
