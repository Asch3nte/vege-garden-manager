import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/services/comparateur_noms.dart';

void main() {
  const comparateur = ComparateurNoms();

  group('replier', () {
    test('lowercases and folds accents and ligatures', () {
      expect(comparateur.replier('Épinard'), 'epinard');
      expect(comparateur.replier('Œillet'), 'oeillet');
      expect(comparateur.replier('MÂCHE à couper'), 'mache a couper');
      expect(comparateur.replier('Cæsalpinia'), 'caesalpinia');
    });

    test('drops combining marks of decomposed text', () {
      expect(comparateur.replier('E\u0301chalote'), 'echalote');
    });

    test('folds other Latin letters', () {
      expect(comparateur.replier('Søren Kłos Straße Ýr'), 'soren klos strasse yr');
    });
  });

  group('comparer', () {
    test('sorts accented names with their base letter', () {
      final noms = ['Tomate', 'Échalote', 'Courgette', 'Fraise']
        ..sort(comparateur.comparer);
      expect(noms, ['Courgette', 'Échalote', 'Fraise', 'Tomate']);
    });

    test('ignores case', () {
      final noms = ['basilic', 'Ail', 'ciboulette', 'Bette']
        ..sort(comparateur.comparer);
      expect(noms, ['Ail', 'basilic', 'Bette', 'ciboulette']);
    });

    test('folds a ligature to its two letters', () {
      final noms = ['Oignon', 'Œillet', 'Oseille']
        ..sort(comparateur.comparer);
      expect(noms, ['Œillet', 'Oignon', 'Oseille']);
    });

    test('orders names equal once folded deterministically', () {
      expect(comparateur.comparer('Pêche', 'Peche'), isNot(0));
      expect(comparateur.comparer('Pêche', 'Peche'),
          -comparateur.comparer('Peche', 'Pêche'));
      expect(comparateur.comparer('Tomate', 'Tomate'), 0);
    });
  });
}
