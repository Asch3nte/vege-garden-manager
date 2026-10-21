import 'potager_exception.dart';

/// Thrown when a plant is incompatible with the potager's climate zone.
class ZoneClimatiqueIncompatibleException extends PotagerException {
  final String planteId;

  ZoneClimatiqueIncompatibleException(this.planteId)
      : super('Plant "$planteId" is not compatible with this climate zone.');
}
