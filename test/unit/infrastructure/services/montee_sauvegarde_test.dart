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
      tache('arroser : tomate'),
      tache('Arroser le compost'),
      tache('Arroser : Tomate', plantationId: null),
      tache('Arroser : Tomate', type: 'desherbage'),
    ];
    const MonteeSauvegarde().monter({'taches': lignes}, 6);

    expect(lignes.map((l) => l['generee']), [1, 1, 1, null, null, null]);
    expect(lignes.map((l) => l['titre']), [
      null,
      null,
      null,
      'Arroser le compost',
      'Arroser : Tomate',
      'Arroser : Tomate',
    ]);
  });

  test('v7 → v8 gives each zone the colour it showed by position', () {
    Map<String, dynamic> zone(String potager, int ordre,
            {bool supprimee = false}) =>
        {
          'potager_id': potager,
          'position_ordre': ordre,
          'deleted_at': supprimee ? 'x' : null,
        };
    final lignes = [
      zone('pot1', 1),
      zone('pot1', 0),
      zone('pot1', 0, supprimee: true),
      zone('pot1', 1),
      zone('pot2', 0),
    ];
    const MonteeSauvegarde().monter({'parcelles': lignes}, 7);

    expect(lignes.map((l) => l['couleur_teinte']),
        ['terracotta', 'vertProfond', null, 'aubergine', 'vertProfond']);
  });

  test('v7 → v8 breaks position ties by creation date', () {
    final tardive = {
      'potager_id': 'pot1',
      'position_ordre': 0,
      'created_at': '2026-02-01',
    };
    final ancienne = {
      'potager_id': 'pot1',
      'position_ordre': 0,
      'created_at': '2026-01-01',
    };
    const MonteeSauvegarde().monter({
      'parcelles': [tardive, ancienne],
    }, 7);

    expect(ancienne['couleur_teinte'], 'vertProfond');
    expect(tardive['couleur_teinte'], 'terracotta');
  });

  test('v7 → v8 tolerates a malformed position', () {
    final ligne = {'potager_id': 'pot1', 'position_ordre': 'x'};
    const MonteeSauvegarde().monter({
      'parcelles': [ligne],
    }, 7);
    expect(ligne['couleur_teinte'], 'vertProfond');
  });

  test('a current backup is left untouched', () {
    final ligne = tache('Arroser : Tomate');
    final zone = {
      'potager_id': 'pot1',
      'position_ordre': 0,
      'couleur_teinte': null,
      'couleur_rgb': 0x123456,
    };
    const MonteeSauvegarde().monter({
      'taches': [ligne],
      'parcelles': [zone],
    }, 8);
    expect(ligne['titre'], 'Arroser : Tomate');
    expect(zone['couleur_teinte'], isNull);
  });
}
