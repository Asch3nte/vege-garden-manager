import '../enums/stade_croissance.dart';

/// Immutable growth state of a plantation at a reference instant: its current
/// [stade] and a [progression] in `[0, 1]` toward the earliest estimated harvest.
///
/// A **result** value object produced by the engine (`CalculateurDatesCulture`),
/// never persisted. The progression is an assumed ratio of elapsed days to the
/// minimum days-to-harvest — an approximation, never a measurement. Domain names
/// are kept in French; the code is documented in English.
/// See `docs/05-modele-de-domaine.md` §4 and `docs/15-elements-differes.md` §3.
class EtatCroissance {
  final StadeCroissance _stade;
  final double _progression;

  const EtatCroissance._(this._stade, this._progression);

  /// Builds a growth state; [progression] is clamped to `[0, 1]`.
  factory EtatCroissance({
    required StadeCroissance stade,
    required double progression,
  }) =>
      EtatCroissance._(stade, progression.clamp(0.0, 1.0).toDouble());

  /// Current growth stage.
  StadeCroissance get stade => _stade;

  /// Progress toward the earliest estimated harvest, in `[0, 1]` (1 = harvest
  /// window reached or passed).
  double get progression => _progression;

  @override
  bool operator ==(Object other) =>
      other is EtatCroissance &&
      other._stade == _stade &&
      other._progression == _progression;

  @override
  int get hashCode => Object.hash(_stade, _progression);

  @override
  String toString() =>
      'EtatCroissance($_stade, ${(_progression * 100).round()}%)';
}
