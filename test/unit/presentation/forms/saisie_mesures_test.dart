import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/enums/unite_quantite.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';
import 'package:pot_a_gerer/presentation/forms/saisie_mesures.dart';

void main() {
  const metrique = SaisieMesures(PreferencesUnites());
  const imperial = SaisieMesures(
    PreferencesUnites.uniforme(SystemeUnites.imperial),
  );

  test('metric entries pass through unchanged', () {
    expect(metrique.surfaceVersM2(2.5), 2.5);
    expect(metrique.surfacePourChamp(2.5), '2.5');
    expect(metrique.surfacePourChamp(3), '3');
    expect(metrique.longueurVersCm(25), 25);
    expect(metrique.longueurPourChamp(25), '25');
    expect(metrique.uniteRecolteParDefaut, UniteSaisieRecolte.kg);
  });

  test('imperial surfaces and lengths convert both ways', () {
    expect(imperial.surfaceVersM2(10.763910416709722), closeTo(1, 1e-9));
    expect(imperial.surfacePourChamp(1), '10.76');
    expect(imperial.longueurVersCm(12), 30);
    expect(imperial.longueurPourChamp(30), '12');
  });

  test('harvest units follow the mass and volume systems', () {
    expect(metrique.unitesRecolte, [
      UniteSaisieRecolte.g,
      UniteSaisieRecolte.kg,
      UniteSaisieRecolte.piece,
      UniteSaisieRecolte.botte,
      UniteSaisieRecolte.litre,
      UniteSaisieRecolte.ml,
    ]);
    expect(imperial.unitesRecolte, [
      UniteSaisieRecolte.oz,
      UniteSaisieRecolte.lb,
      UniteSaisieRecolte.piece,
      UniteSaisieRecolte.botte,
      UniteSaisieRecolte.galUs,
      UniteSaisieRecolte.flOz,
    ]);
  });

  test('imperial harvest amounts are stored in the matching metric unit', () {
    final lb = imperial.quantite(1, UniteSaisieRecolte.lb);
    expect(lb.unite, UniteQuantite.kg);
    expect(lb.valeur, closeTo(0.45359237, 1e-9));
    final gal = imperial.quantite(1, UniteSaisieRecolte.galUs);
    expect(gal.unite, UniteQuantite.litre);
    expect(gal.valeur, closeTo(3.785411784, 1e-9));
    final piece = imperial.quantite(3, UniteSaisieRecolte.piece);
    expect(piece.unite, UniteQuantite.piece);
    expect(piece.valeur, 3);
  });
}
