import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';

FamilleBotanique _famille({
  String id = 'solanaceae',
  String nomScientifique = 'Solanaceae',
  Set<CategoriePlante>? categories,
  Map<String, String>? noms,
  Map<String, String>? descriptions,
  Set<String>? maladies,
  Set<String>? ravageurs,
  int? delaiRetour,
}) =>
    FamilleBotanique(
      id: id,
      nomScientifique: nomScientifique,
      categories: categories ?? {CategoriePlante.legume},
      nomsLocalises: noms ?? {'fr': 'Solanacées', 'en': 'Nightshades'},
      descriptionsLocalisees: descriptions,
      maladiesCommunes: maladies,
      ravageursCommuns: ravageurs,
      delaiRetourAnnees: delaiRetour,
    );

void main() {
  group('FamilleBotanique — construction & invariants', () {
    test('exposes its fields', () {
      final f = _famille(delaiRetour: 4, maladies: {'mildiou'});
      expect(f.id, 'solanaceae');
      expect(f.nomScientifique, 'Solanaceae');
      expect(f.categories, {CategoriePlante.legume});
      expect(f.delaiRetourAnnees, 4);
      expect(f.maladiesCommunes, {'mildiou'});
    });

    test('requires at least one category', () {
      expect(() => _famille(categories: {}), throwsA(isA<AssertionError>()));
    });

    test('requires a French name', () {
      expect(
        () => _famille(noms: {'en': 'Nightshades'}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-lowercase id', () {
      expect(() => _famille(id: 'Solanaceae'), throwsA(isA<AssertionError>()));
    });

    test('rejects a non-positive return delay', () {
      expect(() => _famille(delaiRetour: 0), throwsA(isA<AssertionError>()));
    });
  });

  group('FamilleBotanique — link key normalization', () {
    test('lowercases the scientific name', () {
      expect(FamilleBotanique.normaliserCle('Solanaceae'), 'solanaceae');
    });

    test('strips accents, spaces, hyphens and underscores', () {
      expect(FamilleBotanique.normaliserCle('  Astéracées '), 'asteracees');
      expect(FamilleBotanique.normaliserCle('Amaryllis_lily-aceae'),
          'amaryllislilyaceae');
    });

    test('a family id equals its normalized scientific name', () {
      final f = _famille(id: 'asteraceae', nomScientifique: 'Asteraceae');
      expect(f.id, FamilleBotanique.normaliserCle(f.nomScientifique));
    });
  });

  group('FamilleBotanique — localization & relevance', () {
    test('returns the requested locale, falling back to French', () {
      final f = _famille();
      expect(f.nomLocalise('en'), 'Nightshades');
      expect(f.nomLocalise('es'), 'Solanacées');
    });

    test('description falls back to French then null', () {
      expect(_famille().descriptionLocalisee('fr'), isNull);
      expect(
        _famille(descriptions: {'fr': 'desc'}).descriptionLocalisee('de'),
        'desc',
      );
    });

    test('relevance is checked against the category set', () {
      final f = _famille(
          categories: {CategoriePlante.legume, CategoriePlante.aromatique});
      expect(f.estPertinentePour(CategoriePlante.aromatique), isTrue);
      expect(f.estPertinentePour(CategoriePlante.fleur), isFalse);
    });
  });

  group('FamilleBotanique — immutability & identity', () {
    test('exposed collections are unmodifiable', () {
      final f = _famille(maladies: {'mildiou'});
      expect(() => f.categories.add(CategoriePlante.fleur),
          throwsUnsupportedError);
      expect(() => f.maladiesCommunes.add('x'), throwsUnsupportedError);
      expect(() => f.nomsLocalises['de'] = 'x', throwsUnsupportedError);
    });

    test('equality is by id', () {
      expect(_famille(id: 'solanaceae') == _famille(id: 'solanaceae'), isTrue);
      expect(_famille(id: 'solanaceae') == _famille(id: 'apiaceae'), isFalse);
    });
  });
}
