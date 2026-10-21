import 'potager_exception.dart';

/// Thrown when saving preferences whose stored version cannot be read: the
/// stored row is kept untouched instead of being overwritten.
class PreferencesIllisiblesException extends PotagerException {
  PreferencesIllisiblesException()
      : super('The stored preferences cannot be read; they are kept as is.');
}
