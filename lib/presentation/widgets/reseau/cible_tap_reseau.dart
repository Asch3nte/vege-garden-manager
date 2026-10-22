import 'package:flutter/painting.dart';

/// Resolves which network node a tap designates.
///
/// A painted disc under the tap wins (nearest centre among them); otherwise
/// the nearest node of all within [rayonMax] (Voronoï cells: non-overlapping
/// hitboxes that keep shrunk discs easy to hit).
class CibleTapReseau {
  final double _rayonMax;

  const CibleTapReseau(this._rayonMax);

  double get rayonMax => _rayonMax;

  /// Index in [centres] designated by a tap at [point], or `null`. Nodes in
  /// [masques] have no painted disc of radius [rayonDisque].
  int? trouver({
    required Offset point,
    required List<Offset> centres,
    required double rayonDisque,
    Set<int> masques = const {},
  }) {
    int? disque;
    var distDisque = double.infinity;
    int? proche;
    var distProche = double.infinity;
    for (var i = 0; i < centres.length; i++) {
      final dist = (centres[i] - point).distance;
      if (!masques.contains(i) && dist <= rayonDisque && dist < distDisque) {
        disque = i;
        distDisque = dist;
      }
      if (dist < distProche) {
        proche = i;
        distProche = dist;
      }
    }
    if (disque != null) return disque;
    return distProche <= _rayonMax ? proche : null;
  }
}
