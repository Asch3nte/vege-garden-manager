import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/grandeur_mesure.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';

void main() {
  const m = SystemeUnites.metrique;
  const i = SystemeUnites.imperial;

  test('a preset sets every quantity', () {
    const u = PreferencesUnites.uniforme(i);
    for (final g in GrandeurMesure.values) {
      expect(u.pour(g), i, reason: g.name);
    }
    expect(u.prereglage, i);
  });

  test('defaults to metric', () {
    expect(const PreferencesUnites.uniforme(m), PreferencesUnites());
    expect(PreferencesUnites().prereglage, m);
  });

  test('changing one quantity makes the set custom', () {
    final u = const PreferencesUnites.uniforme(
      m,
    ).avec(GrandeurMesure.longueur, i);
    expect(u.pour(GrandeurMesure.longueur), i);
    expect(u.pour(GrandeurMesure.temperature), m);
    expect(u.prereglage, isNull);
  });

  test('equality is by value', () {
    expect(
      PreferencesUnites().avec(GrandeurMesure.masse, i),
      PreferencesUnites().avec(GrandeurMesure.masse, i),
    );
    expect(
      PreferencesUnites().avec(GrandeurMesure.masse, i),
      isNot(PreferencesUnites().avec(GrandeurMesure.volume, i)),
    );
  });
}
