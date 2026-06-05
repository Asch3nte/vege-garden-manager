import 'potager_exception.dart';

/// Thrown when no plant sheet matches a referenced plant id (e.g. a plantation
/// references a `planteId` absent from the YAML catalogue).
///
/// See `docs/05-modele-de-domaine.md` §8.
class FichePlanteIntrouvableException extends PotagerException {
  final String planteId;

  FichePlanteIntrouvableException(this.planteId)
      : super('No plant sheet found for id "$planteId".');
}
