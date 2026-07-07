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
      l10n.resumeEffet(EffetEquipement.pourType(TypeEquipement.oya)),
      isNotEmpty,
    );
    // A neutral effect yields no chips.
    expect(l10n.resumeEffet(EffetEquipement.neutre), isEmpty);
  });
}
