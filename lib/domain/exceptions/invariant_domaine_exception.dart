import 'potager_exception.dart';

/// Thrown when data breaks a domain invariant (empty id, end date before the
/// start date…), in every build mode.
class InvariantDomaineException extends PotagerException {
  InvariantDomaineException(super.message);

  /// Throws an [InvariantDomaineException] with [message] unless [condition].
  static void verifier(bool condition, String message) {
    if (!condition) throw InvariantDomaineException(message);
  }
}
