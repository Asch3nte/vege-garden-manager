import 'potager_exception.dart';

/// Thrown when a YAML botanical-family sheet is syntactically or structurally
/// invalid (missing required field, id not matching the normalized scientific
/// name, unknown category…).
///
/// At load time a corrupt family sheet is logged and skipped — the app does not
/// crash (same robustness contract as the plant catalogue, ADR-0006).
class FamilleBotaniqueInvalideException extends PotagerException {
  /// Identifier of the offending sheet (its `id` or file name).
  final String source;

  /// Human-readable reason the sheet was rejected.
  final String raison;

  FamilleBotaniqueInvalideException(this.source, this.raison)
      : super('Invalid family sheet "$source": $raison');
}
