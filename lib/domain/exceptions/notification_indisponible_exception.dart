import 'potager_exception.dart';

/// Thrown when a local notification cannot be scheduled or cancelled (the OS
/// rejected it, notifications are disabled, or the platform plugin failed).
///
/// The optional [cause] carries the underlying error for diagnostics.
///
/// See `docs/05-modele-de-domaine.md` §8.
class NotificationIndisponibleException extends PotagerException {
  /// The underlying platform error, when this wraps one.
  final Object? cause;

  NotificationIndisponibleException(super.message, {this.cause});
}
