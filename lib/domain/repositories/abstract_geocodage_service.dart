import '../exceptions/geocodage_indisponible_exception.dart';
import '../value_objects/lieu_trouve.dart';
import '../value_objects/localisation.dart';

/// Contract for geocoding: naming a location and searching places by name.
///
/// The single implementation uses the Nominatim / OpenStreetMap public API;
/// future implementations could substitute another provider without touching
/// callers.
abstract class AbstractGeocodageService {
  /// Returns the nearest locality name for [loc] in the user's preferred
  /// language (French), or `null` when the location is undefined or the name
  /// unavailable. Never throws.
  Future<String?> obtenirNomLocalite(Localisation loc);

  /// Names the locality at ([latitude], [longitude]) with its region and
  /// country, or `null` when unavailable. Never throws.
  Future<LieuTrouve?> identifierLieu(double latitude, double longitude);

  /// Places whose name matches [texte], best matches first; empty when none.
  ///
  /// Throws [GeocodageIndisponibleException] when the service cannot answer.
  Future<List<LieuTrouve>> rechercherLieux(String texte);
}
