import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/app/textes_notifications_arb.dart';

void main() {
  final fr = TextesNotificationsArb(() => 'fr');
  final en = TextesNotificationsArb(() => 'en');

  test('exposes the language it writes in', () {
    expect(fr.langue, 'fr');
    expect(en.langue, 'en');
  });

  group('titreRecapArrosage', () {
    test('names up to three crops, then counts the rest', () {
      expect(fr.titreRecapArrosage(['Tomate'], 1), 'Arroser Tomate');
      expect(fr.titreRecapArrosage(['Tomate', 'Basilic'], 2),
          'Arroser Tomate, Basilic');
      expect(
          fr.titreRecapArrosage(
              ['Tomate', 'Basilic', 'Courgette', 'Poivron'], 4),
          'Arroser Tomate, Basilic, Courgette +1');
    });

    test('counts the unnamed crops in the rest', () {
      expect(fr.titreRecapArrosage(['Tomate'], 2), 'Arroser Tomate +1');
    });

    test('generic title without any name', () {
      expect(fr.titreRecapArrosage(const [], 2), 'Arrosage à prévoir');
    });

    test('English', () {
      expect(en.titreRecapArrosage(['Tomato'], 1), 'Water Tomato');
    });
  });

  group('corpsRecapArrosage', () {
    test('lists every crop', () {
      expect(fr.corpsRecapArrosage(['Tomate', 'Basilic'], 2),
          "Cultures à arroser aujourd'hui : Tomate, Basilic.");
    });

    test('a single crop', () {
      expect(fr.corpsRecapArrosage(['Tomate'], 1),
          "Tomate a besoin d'eau aujourd'hui.");
    });

    test('counts when no name is known', () {
      expect(fr.corpsRecapArrosage(const [], 1),
          "Une culture a besoin d'eau aujourd'hui.");
      expect(fr.corpsRecapArrosage(const [], 3),
          "3 cultures ont besoin d'eau aujourd'hui.");
    });

    test('English', () {
      expect(en.corpsRecapArrosage(['Tomato', 'Basil'], 2),
          'Crops to water today: Tomato, Basil.');
    });
  });
}
