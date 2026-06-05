import 'potager_exception.dart';

/// Thrown when a plant is incompatible with the potager's climate zone.
///
/// See `docs/05-modele-de-domaine.md` §8.
class ZoneClimatiqueIncompatibleException extends PotagerException {
  final String planteId;

  ZoneClimatiqueIncompatibleException(this.planteId)
      : super('Plant "$planteId" is not compatible with this climate zone.');
}
