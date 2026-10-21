import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/services/montee_sauvegarde.dart';

void main() {
  Map<String, dynamic> tache(String titre,
          {String type = 'arrosage', String? plantationId = 'pl1'}) =>
      {'titre': titre, 'type': type, 'plantation_id': plantationId};

  test('v6 → v7 converts only the engine watering titles', () {
    final lignes = [
      tache('Arroser : Tomate'),
      tache('Arroser'),
      tache('Arroser le compost'),
      tache('Arroser : Tomate', plantationId: null),
      tache('Arroser : Tomate', type: 'desherbage'),
    ];
    const MonteeSauvegarde().monter({'taches': lignes}, 6);

    expect(lignes.map((l) => l['generee']), [1, 1, null, null, null]);
    expect(lignes.map((l) => l['titre']), [
      null,
      null,
      'Arroser le compost',
      'Arroser : Tomate',
      'Arroser : Tomate',
    ]);
  });

  test('a current backup is left untouched', () {
    final ligne = tache('Arroser : Tomate');
    const MonteeSauvegarde().monter({'taches': [ligne]}, 7);
    expect(ligne['titre'], 'Arroser : Tomate');
  });
}
