import 'potager_exception.dart';

/// Thrown when a YAML plant sheet is syntactically or structurally invalid
/// (missing required field, inconsistent values…).
///
/// At load time a corrupt sheet is logged and skipped — the app does not crash
/// (see `docs/07-base-de-connaissances-yaml.md` §6).
class FichePlanteInvalideException extends PotagerException {
  /// Identifier of the offending sheet (its `id` or file name).
  final String source;

  /// Human-readable reason the sheet was rejected.
  final String raison;

  FichePlanteInvalideException(this.source, this.raison)
      : super('Invalid plant sheet "$source": $raison');
}
