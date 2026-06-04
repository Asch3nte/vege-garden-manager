import '../enums/unite_quantite.dart';
import 'potager_exception.dart';

/// Thrown when a quantity is converted (or combined) between two units of
/// different natures — e.g. kilograms to litres, or pieces to bunches.
///
/// See `docs/05-modele-de-domaine.md` §4.5 & §8.
class ConversionUniteIncompatibleException extends PotagerException {
  /// Unit the quantity is expressed in.
  final UniteQuantite source;

  /// Unit the conversion targets.
  final UniteQuantite cible;

  ConversionUniteIncompatibleException(this.source, this.cible)
      : super(
          'Cannot convert from ${source.name} (${source.nature.name}) '
          'to ${cible.name} (${cible.nature.name}): different natures.',
        );
}
