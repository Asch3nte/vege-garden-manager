import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';

void main() {
  test('only pots and planters have renewed soil', () {
    expect(
      {for (final t in TypeParcelle.values) t: t.solRenouvele},
      {
        TypeParcelle.pleineTerre: false,
        TypeParcelle.bacSureleve: false,
        TypeParcelle.jardiniere: true,
        TypeParcelle.pot: true,
        TypeParcelle.serre: false,
        TypeParcelle.butte: false,
        TypeParcelle.autre: false,
      },
    );
  });
}
