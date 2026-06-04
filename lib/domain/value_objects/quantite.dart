import '../enums/unite_quantite.dart';
import '../exceptions/conversion_unite_incompatible_exception.dart';

/// Immutable value object pairing a numeric value with a [UniteQuantite].
///
/// A quantity is never negative (enforced by assertion). Conversions and
/// arithmetic are only allowed between units of the **same nature** (mass↔mass,
/// volume↔volume); any cross-nature operation throws a typed
/// [ConversionUniteIncompatibleException]. Equality is semantic: two quantities
/// are equal when they describe the same amount of the same nature
/// (`1 kg == 1000 g`).
///
/// Domain names are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §4.5.
class Quantite {
  final double _valeur;
  final UniteQuantite _unite;

  /// Creates a quantity of [valeur] expressed in [unite]. [valeur] must be `>= 0`.
  const Quantite(this._valeur, this._unite)
      : assert(_valeur >= 0, 'A quantity cannot be negative.');

  /// The numeric value, expressed in [unite].
  double get valeur => _valeur;

  /// The unit this quantity is expressed in.
  UniteQuantite get unite => _unite;

  /// The equivalent value expressed in the base unit of this quantity's nature
  /// (grams for mass, millilitres for volume, the value itself for counts).
  double get _enBase => _valeur * _unite.facteurVersBase;

  /// Whether this quantity can be converted to [cible] (same nature).
  bool estConvertibleVers(UniteQuantite cible) => _unite.nature == cible.nature;

  /// Converts this quantity to [cible].
  ///
  /// Throws [ConversionUniteIncompatibleException] when [cible] is of a different
  /// nature than this quantity's unit.
  Quantite convertirVers(UniteQuantite cible) {
    if (!estConvertibleVers(cible)) {
      throw ConversionUniteIncompatibleException(_unite, cible);
    }
    return Quantite(_enBase / cible.facteurVersBase, cible);
  }

  /// Returns the sum of this quantity and [autre], expressed in this unit.
  ///
  /// Throws [ConversionUniteIncompatibleException] if the natures differ.
  Quantite operator +(Quantite autre) =>
      Quantite(_valeur + autre.convertirVers(_unite)._valeur, _unite);

  /// Returns the difference, expressed in this unit. The result must stay `>= 0`.
  ///
  /// Throws [ConversionUniteIncompatibleException] if the natures differ.
  Quantite operator -(Quantite autre) =>
      Quantite(_valeur - autre.convertirVers(_unite)._valeur, _unite);

  @override
  bool operator ==(Object other) =>
      other is Quantite &&
      other._unite.nature == _unite.nature &&
      other._enBase == _enBase;

  @override
  int get hashCode => Object.hash(_unite.nature, _enBase);

  @override
  String toString() => 'Quantite($_valeur ${_unite.name})';
}
