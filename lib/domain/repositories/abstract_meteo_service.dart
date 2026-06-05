import '../value_objects/donnees_meteo.dart';
import '../value_objects/localisation.dart';
import '../value_objects/prevision_meteo.dart';

/// Contract for fetching weather (implemented with Open-Meteo in the
/// infrastructure layer).
///
/// See `docs/05-modele-de-domaine.md` §7.
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
}
