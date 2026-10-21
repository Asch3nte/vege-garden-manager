import 'potager_exception.dart';

/// Thrown when the device location cannot be obtained: the location service is
/// off, permission was denied, or the platform query failed.
///
/// The optional [cause] carries the underlying error for diagnostics.
class GeolocalisationIndisponibleException extends PotagerException {
  /// The underlying platform error, when this wraps one.
  final Object? cause;

  GeolocalisationIndisponibleException(super.message, {this.cause});
}
