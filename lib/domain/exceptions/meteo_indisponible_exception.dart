import 'potager_exception.dart';

/// Thrown when weather data cannot be obtained: the location is undefined
/// (opt-out), the remote service is unreachable (offline, timeout, server
/// error), or its response cannot be parsed, **and** no cached fallback is
/// available.
///
/// The optional [cause] carries the underlying error for diagnostics; it is
/// never shown to the user (user-facing messages are localised at the
/// presentation layer).
///
/// See `docs/05-modele-de-domaine.md` §8.
class MeteoIndisponibleException extends PotagerException {
  /// The underlying error, when this exception wraps one (network/parse error).
  final Object? cause;

  MeteoIndisponibleException(super.message, {this.cause});
}
