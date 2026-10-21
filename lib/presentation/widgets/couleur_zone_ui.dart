import 'package:flutter/material.dart';

import '../../app/theme/couleurs_app.dart';
import '../../domain/enums/teinte_zone.dart';
import '../../domain/value_objects/couleur_zone.dart';

/// Display colour of a [CouleurZone].
extension CouleurZoneUi on CouleurZone {
  Color get couleur {
    final rgb = this.rgb;
    if (rgb != null) return Color(0xFF000000 | rgb);
    return switch (teinte!) {
      TeinteZone.vertProfond => CouleursApp.decoVertProfond,
      TeinteZone.terracotta => CouleursApp.accentChaudClair,
      TeinteZone.aubergine => CouleursApp.decoAubergine,
      TeinteZone.vertMoyen => CouleursApp.decoVertMoyen,
      TeinteZone.bordeaux => CouleursApp.decoBordeaux,
      TeinteZone.terre => CouleursApp.decoTerre,
    };
  }
}
