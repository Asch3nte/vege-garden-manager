import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/value_objects/statistiques_stockage.dart';

void main() {
  test('totalLignes sums every table', () {
    final stats = StatistiquesStockage(
      tables: const [
        StatistiqueTable(nom: 'potagers', lignes: 2),
        StatistiqueTable(nom: 'plantations', lignes: 5),
        StatistiqueTable(nom: 'taches', lignes: 0),
      ],
      tailleOctets: 4096,
    );
    expect(stats.totalLignes, 7);
  });

  test('exposes an unmodifiable table list', () {
    final stats = StatistiquesStockage(
      tables: [const StatistiqueTable(nom: 'potagers', lignes: 1)],
      tailleOctets: 0,
    );
    expect(
      () => stats.tables.add(const StatistiqueTable(nom: 'x', lignes: 0)),
      throwsUnsupportedError,
    );
  });

  test('StatistiqueTable has value equality', () {
    const a = StatistiqueTable(nom: 'potagers', lignes: 2);
    const b = StatistiqueTable(nom: 'potagers', lignes: 2);
    const c = StatistiqueTable(nom: 'potagers', lignes: 3);
    expect(a, b);
    expect(a, isNot(c));
  });
}
