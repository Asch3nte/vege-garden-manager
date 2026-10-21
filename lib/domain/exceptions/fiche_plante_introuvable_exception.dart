import 'potager_exception.dart';

/// Thrown when no plant sheet matches a referenced plant id (e.g. a plantation
/// references a `planteId` absent from the YAML catalogue).
class FichePlanteIntrouvableException extends PotagerException {
  final String planteId;

  FichePlanteIntrouvableException(this.planteId)
      : super('No plant sheet found for id "$planteId".');
}
