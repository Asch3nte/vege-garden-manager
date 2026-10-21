import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/app/theme/couleurs_app.dart';
import 'package:pot_a_gerer/domain/enums/teinte_zone.dart';
import 'package:pot_a_gerer/domain/value_objects/couleur_zone.dart';
import 'package:pot_a_gerer/presentation/widgets/couleur_zone_ui.dart';

void main() {
  test('each tint maps to its palette colour, in the former order', () {
    expect(
      [for (final t in TeinteZone.values) CouleurZone.teinte(t).couleur],
      const [
        CouleursApp.decoVertProfond,
        CouleursApp.accentChaudClair,
        CouleursApp.decoAubergine,
        CouleursApp.decoVertMoyen,
        CouleursApp.decoBordeaux,
        CouleursApp.decoTerre,
      ],
    );
  });

  test('a custom colour is opaque with its RGB value', () {
    expect(
      CouleurZone.personnalisee(0x3366CC).couleur,
      const Color(0xFF3366CC),
    );
  });
}
