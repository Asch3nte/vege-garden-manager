import '../exceptions/invariant_domaine_exception.dart';
import 'surface.dart';

/// Length and width of a rectangular zone, in centimetres.
class DimensionsZone {
  final double _longueurCm;
  final double _largeurCm;

  const DimensionsZone._(this._longueurCm, this._largeurCm);

  factory DimensionsZone({required double longueurCm, required double largeurCm}) {
    InvariantDomaineException.verifier(
      longueurCm > 0 && largeurCm > 0,
      'zone sides must be > 0',
    );
    return DimensionsZone._(longueurCm, largeurCm);
  }

  double get longueurCm => _longueurCm;
  double get largeurCm => _largeurCm;

  /// The area the two sides enclose.
  Surface get surface =>
      Surface.enCentimetresCarres(_longueurCm * _largeurCm);

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
