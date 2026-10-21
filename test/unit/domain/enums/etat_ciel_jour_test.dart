import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/etat_ciel_jour.dart';

void main() {
  group('depuisWmo', () {
    const attendus = {
      0: EtatCielJour.ensoleille,
      1: EtatCielJour.ensoleille,
      2: EtatCielJour.nuageux,
      3: EtatCielJour.couvert,
      45: EtatCielJour.brouillard,
      48: EtatCielJour.brouillard,
      51: EtatCielJour.pluie,
      67: EtatCielJour.pluie,
      71: EtatCielJour.neige,
      77: EtatCielJour.neige,
      80: EtatCielJour.pluie,
      82: EtatCielJour.pluie,
      85: EtatCielJour.neige,
      86: EtatCielJour.neige,
      95: EtatCielJour.orage,
      99: EtatCielJour.orage,
      100: EtatCielJour.couvert,
    };
    attendus.forEach((code, etat) {
      test('$code → ${etat.name}',
          () => expect(EtatCielJour.depuisWmo(code), etat));
    });
  });
}
