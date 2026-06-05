import 'potager_exception.dart';

/// Thrown when a plant is planted in a month outside its valid window for the
/// current hemisphere/climate.
///
/// See `docs/05-modele-de-domaine.md` §8.
class PeriodePlantationInvalideException extends PotagerException {
  final String planteId;

  /// The offending month (1–12).
  final int mois;

  PeriodePlantationInvalideException(this.planteId, this.mois)
      : super(
          'Plant "$planteId" cannot be planted in month $mois for this climate.',
        );
}
