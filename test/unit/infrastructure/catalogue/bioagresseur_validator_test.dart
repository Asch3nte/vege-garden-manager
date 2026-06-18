import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/exceptions/bioagresseur_invalide_exception.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/bioagresseur_validator.dart';

void main() {
  const validator = BioagresseurValidator();

  Map<dynamic, dynamic> entry({
    Object? type = 'maladie',
    Object? nom = 'Mildiou',
    Object? codeEppo,
  }) =>
      {
        'type': type,
        'code_eppo': ?codeEppo,
        'i18n': {
          'fr': {'nom': nom},
        },
      };

  test('accepts a well-formed entry', () {
    expect(
        () => validator.valider('mildiou', entry(), source: 'mildiou'),
        returnsNormally);
  });

  test('accepts an optional code_eppo', () {
    expect(
        () => validator.valider('mildiou', entry(codeEppo: 'PHYTIN'),
            source: 'mildiou'),
        returnsNormally);
  });

  test('rejects a non-normalized slug', () {
    expect(
        () => validator.valider('Mildiou Tardif', entry(), source: 'x'),
        throwsA(isA<BioagresseurInvalideException>()));
  });

  test('rejects an unknown type', () {
    expect(
        () => validator.valider('mildiou', entry(type: 'champignon'),
            source: 'mildiou'),
        throwsA(isA<BioagresseurInvalideException>()));
  });

  test('rejects a missing or empty French name', () {
    expect(
        () => validator.valider('mildiou', entry(nom: null), source: 'mildiou'),
        throwsA(isA<BioagresseurInvalideException>()));
    expect(
        () => validator.valider('mildiou', entry(nom: '  '), source: 'mildiou'),
        throwsA(isA<BioagresseurInvalideException>()));
  });

  test('rejects an empty code_eppo', () {
    expect(
        () => validator.valider('mildiou', entry(codeEppo: '  '),
            source: 'mildiou'),
        throwsA(isA<BioagresseurInvalideException>()));
  });
}
