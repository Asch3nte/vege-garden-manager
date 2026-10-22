import 'potager_exception.dart';

/// Thrown when a place search cannot reach the geocoding service or cannot
/// read its response.
class GeocodageIndisponibleException extends PotagerException {
  /// The underlying network or parse error, for diagnostics only.
  final Object? cause;

  GeocodageIndisponibleException(super.message, {this.cause});
}
