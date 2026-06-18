import 'potager_exception.dart';

/// Thrown when an entry of the bioaggressor reference is structurally invalid
/// (missing required field, slug not normalized, unknown `type`…).
///
/// At load time a corrupt reference entry is logged and skipped — the app does
/// not crash (same robustness contract as the plant catalogue and the family
/// reference, ADR-0006).
class BioagresseurInvalideException extends PotagerException {
  /// Identifier of the offending entry (its slug or the file name).
  final String source;

  /// Human-readable reason the entry was rejected.
  final String raison;

  BioagresseurInvalideException(this.source, this.raison)
      : super('Invalid bioaggressor "$source": $raison');
}
