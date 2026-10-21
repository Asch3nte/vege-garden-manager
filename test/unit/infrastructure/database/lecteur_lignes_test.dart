import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/exceptions/invariant_domaine_exception.dart';
import 'package:pot_a_gerer/infrastructure/database/lecteur_lignes.dart';

void main() {
  late List<(String, String)> signalees;
  late LecteurLignes lecteur;

  setUp(() {
    signalees = [];
    lecteur = LecteurLignes((table, id, _) => signalees.add((table, id)));
  });

  int versEntite(String ligne) => switch (ligne) {
        'invariant' => throw InvariantDomaineException('bad'),
        'enum' => throw ArgumentError.value(ligne),
        'date' => throw const FormatException('bad date'),
        'json' => (<Object>[1] as dynamic).cast<String>().first.length,
        _ => ligne.length,
      };

  test('sets aside the invalid rows and reports each one', () {
    final lignes = ['ab', 'invariant', 'enum', 'date', 'json', 'abc'];
    final entites = lecteur.lire('taches', lignes, versEntite, (l) => l);

    expect(entites, [2, 3]);
    expect(signalees, [
      ('taches', 'invariant'),
      ('taches', 'enum'),
      ('taches', 'date'),
      ('taches', 'json'),
    ]);
    expect(() => entites.add(1), throwsUnsupportedError);
  });

  test('a single invalid row reads as absent', () {
    int? lire(String? ligne) =>
        lecteur.lireUne<String, int>('taches', ligne, versEntite, (l) => l);

    expect(lire('invariant'), isNull);
    expect(lire(null), isNull);
    expect(lire('ab'), 2);
    expect(signalees, [('taches', 'invariant')]);
  });

  test('a programming error is not swallowed', () {
    expect(
      () => lecteur.lire<String, int>(
          'taches', ['x'], (_) => throw StateError('bug'), (l) => l),
      throwsStateError,
    );
  });
}
