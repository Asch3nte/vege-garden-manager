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
        _ => ligne.length,
      };

  test('sets aside the invalid rows and reports each one', () {
    final entites = lecteur.lire(
        'taches', ['ab', 'invariant', 'enum', 'date', 'abc'], versEntite, (l) => l);

    expect(entites, [2, 3]);
    expect(signalees,
        [('taches', 'invariant'), ('taches', 'enum'), ('taches', 'date')]);
    expect(() => entites.add(1), throwsUnsupportedError);
  });

  test('a single invalid row reads as absent', () {
    expect(lecteur.lireUne<String, int>('taches', 'invariant', versEntite, (l) => l), isNull);
    expect(lecteur.lireUne<String, int>('taches', null, versEntite, (l) => l), isNull);
    expect(lecteur.lireUne<String, int>('taches', 'ab', versEntite, (l) => l), 2);
    expect(signalees, [('taches', 'invariant')]);
  });

  test('a programming error is not swallowed', () {
    expect(
      () => lecteur.lire<String, int>('taches', ['x'], (_) => throw StateError('bug'),
          (l) => l),
      throwsStateError,
    );
  });
}
