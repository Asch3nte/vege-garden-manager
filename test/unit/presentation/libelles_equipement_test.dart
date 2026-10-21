// Exhaustiveness of the equipment enum labels (pattern D6): every enum value
// must have a non-empty French label and an icon, and the effect summary must
// reflect a type's effect.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/etat_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/value_objects/effet_equipement.dart';
import 'package:pot_a_gerer/l10n/app_localizations.dart';
import 'package:pot_a_gerer/presentation/widgets/libelles_enums.dart';
import 'package:pot_a_gerer/domain/enums/systeme_unites.dart';
import 'package:pot_a_gerer/domain/value_objects/preferences_unites.dart';
import 'package:pot_a_gerer/presentation/widgets/formateur_mesures.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  test('every TypeEquipement has a non-empty label and an icon', () {
    for (final t in TypeEquipement.values) {
      expect(l10n.typeEquipement(t), isNotEmpty, reason: t.name);
      expect(iconeTypeEquipement(t), isA<IconData>(), reason: t.name);
    }
  });

  test('every EtatEquipement has a non-empty label', () {
    for (final e in EtatEquipement.values) {
      expect(l10n.etatEquipement(e), isNotEmpty, reason: e.name);
    }
  });

  test('resumeEffet describes a type effect and stays empty when neutral', () {
    // An oya cuts the water need — the summary is non-empty.
    expect(
      l10n.resumeEffet(EffetEquipement.pourType(TypeEquipement.oya),
          FormateurMesures(l10n, const PreferencesUnites())),
      isNotEmpty,
    );
    // A neutral effect yields no chips.
    expect(
        l10n.resumeEffet(EffetEquipement.neutre,
            FormateurMesures(l10n, const PreferencesUnites())),
        isEmpty);
  });

  test('hardiness zones use the official USDA °F bounds in imperial', () {
    final imperial = FormateurMesures(
        l10n, const PreferencesUnites.uniforme(SystemeUnites.imperial));
    expect(l10n.rusticiteDescription(ZoneRusticite.zone1, imperial),
        'Minimales hivernales de -60 à -50 °F.');
    expect(l10n.rusticiteDescription(ZoneRusticite.zone8, imperial),
        'Minimales hivernales de 10 à 20 °F.');
    expect(
        l10n.rusticiteDescription(
            ZoneRusticite.zone8, FormateurMesures(l10n, const PreferencesUnites())),
        'Minimales hivernales de -12 à -7 °C.');
  });

  test('resumeEffet shows the warmth gain in the chosen scale', () {
    final chassis = EffetEquipement.pourType(TypeEquipement.chassis);
    expect(
        l10n.resumeEffet(
            chassis, FormateurMesures(l10n, const PreferencesUnites())),
        contains('+3 °C'));
    expect(
        l10n.resumeEffet(
            chassis,
            FormateurMesures(l10n,
                const PreferencesUnites.uniforme(SystemeUnites.imperial))),
        contains('+5,4 °F'));
  });
}
