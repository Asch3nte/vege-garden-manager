import '../exceptions/invariant_domaine_exception.dart';
import 'surface.dart';

/// Length and width of a rectangular zone, in whole centimetres.
class DimensionsZone {
  final int _longueurCm;
  final int _largeurCm;

  const DimensionsZone._(this._longueurCm, this._largeurCm);

  factory DimensionsZone({required int longueurCm, required int largeurCm}) {
    InvariantDomaineException.verifier(
      longueurCm > 0 && largeurCm > 0,
      'zone sides must be > 0',
    );
    return DimensionsZone._(longueurCm, largeurCm);
  }

  int get longueurCm => _longueurCm;
  int get largeurCm => _largeurCm;

  /// The area the two sides enclose.
  Surface get surface =>
      Surface.enCentimetresCarres((_longueurCm * _largeurCm).toDouble());

  /// Whether [autre] is the area of these sides, give or take rounding.
  bool concordeAvec(Surface autre) =>
      (surface.enMetresCarres - autre.enMetresCarres).abs() <= _toleranceM2;

  /// Rounding slack of a surface comparison (1 mm²).
  static const double _toleranceM2 = 1e-6;

  @override
  bool operator ==(Object other) =>
      other is DimensionsZone &&
      other._longueurCm == _longueurCm &&
      other._largeurCm == _largeurCm;

  @override
  int get hashCode => Object.hash(_longueurCm, _largeurCm);

  @override
  String toString() => 'DimensionsZone(${_longueurCm}cm × ${_largeurCm}cm)';
}
