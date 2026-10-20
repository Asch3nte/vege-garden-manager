import 'potager_exception.dart';

/// Thrown when a backup document cannot be imported: malformed JSON, missing
/// structure, an unsupported schema version, or rows the schema rejects.
///
/// The optional [cause] carries the underlying error for diagnostics.
///
/// See `docs/05-modele-de-domaine.md` §8.
class SauvegardeInvalideException extends PotagerException {
  /// The underlying error, when this wraps one (e.g. a JSON parse error).
  final Object? cause;

  SauvegardeInvalideException(super.message, {this.cause});
}
