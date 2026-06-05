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

  /// Forecast for the next [nbJours] days at [loc].
  Future<List<PrevisionMeteo>> obtenirPrevisions(Localisation loc, int nbJours);
}
