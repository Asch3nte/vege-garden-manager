import '../value_objects/localisation.dart';

/// Contract for reverse-geocoding a [Localisation] into a human-readable
/// locality name.
///
/// The single implementation uses the Nominatim / OpenStreetMap public API
/// (validated in ADR-0016); future implementations could substitute another
/// provider without touching callers.
///
/// Returns `null` — never throws — when the location is undefined, the service
/// is unavailable, or no locality name can be resolved (e.g. a location far
/// from any known settlement).
abstract class AbstractGeocodageService {
  /// Returns the nearest locality name for [loc] in the user's preferred
  /// language (French), or `null` when unavailable.
  ///
  /// Callers must handle the `null` case gracefully (display a fallback).
  Future<String?> obtenirNomLocalite(Localisation loc);
}
