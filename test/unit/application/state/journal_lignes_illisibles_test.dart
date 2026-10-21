import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/state/journal_lignes_illisibles.dart';

void main() {
  test('counts each unreadable row once, whatever the number of reads', () {
    final journal = JournalLignesIllisibles()
      ..signaler('taches', 't1', const FormatException('x'))
      ..signaler('taches', 't1', const FormatException('x'))
      ..signaler('plantations', 't1', const FormatException('x'));

    expect(journal.nombre, 2);
  });

  test('vider forgets every row', () {
    final journal = JournalLignesIllisibles()
      ..signaler('taches', 't1', const FormatException('x'))
      ..vider();

    expect(journal.nombre, 0);
  });
}
