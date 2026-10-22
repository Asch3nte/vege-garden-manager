import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/presentation/widgets/reseau/cible_tap_reseau.dart';

void main() {
  const cible = CibleTapReseau(28);

  test('picks the nearest node within the max radius', () {
    final i = cible.trouver(
      point: const Offset(20, 0),
      centres: const [Offset(0, 0), Offset(100, 0)],
      rayonDisque: 5,
    );
    expect(i, 0);
  });

  test('returns null beyond the max radius', () {
    final i = cible.trouver(
      point: const Offset(50, 0),
      centres: const [Offset(0, 0), Offset(100, 0)],
      rayonDisque: 5,
    );
    expect(i, isNull);
  });

  test('a painted disc under the tap wins over a nearer hidden node', () {
    // Node 0 is painted (radius 9.5) and contains the tap; node 1 is hidden
    // but its centre is nearer.
    final i = cible.trouver(
      point: const Offset(7, 0),
      centres: const [Offset(0, 0), Offset(12, 0)],
      rayonDisque: 9.5,
      masques: const {1},
    );
    expect(i, 0);
  });

  test('a hidden node is still reachable when no painted disc is hit', () {
    final i = cible.trouver(
      point: const Offset(30, 0),
      centres: const [Offset(0, 0), Offset(40, 0)],
      rayonDisque: 5,
      masques: const {1},
    );
    expect(i, 1);
  });
}
