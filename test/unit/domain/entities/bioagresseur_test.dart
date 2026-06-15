import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/bioagresseur.dart';
import 'package:pot_a_gerer/domain/enums/type_bioagresseur.dart';

void main() {
  group('Bioagresseur.normaliserSlug', () {
    test('lowercases and keeps a single-word name', () {
      expect(Bioagresseur.normaliserSlug('Mildiou'), 'mildiou');
    });

    test('turns spaces into underscores', () {
      expect(Bioagresseur.normaliserSlug('Mouche de la carotte'),
          'mouche_de_la_carotte');
    });

    test('strips accents and apostrophes, expands ligatures', () {
      expect(Bioagresseur.normaliserSlug('Œil de paon'), 'oeil_de_paon');
      expect(Bioagresseur.normaliserSlug('Piéride'), 'pieride');
      expect(Bioagresseur.normaliserSlug("Rouille de l'œillet"),
          'rouille_de_loeillet');
    });

    test('is idempotent on an already-normalized slug', () {
      const slug = 'mouche_du_chou';
      expect(Bioagresseur.normaliserSlug(slug), slug);
    });
  });

  group('Bioagresseur', () {
    Bioagresseur build() => Bioagresseur(
          id: 'mildiou',
          type: TypeBioagresseur.maladie,
          nomsLocalises: {'fr': 'Mildiou', 'en': 'Late blight'},
          descriptionsLocalisees: {'fr': 'Maladie cryptogamique.'},
          codeEppo: 'PHYTIN',
        );

    test('exposes its fields', () {
      final b = build();
      expect(b.id, 'mildiou');
      expect(b.type, TypeBioagresseur.maladie);
      expect(b.codeEppo, 'PHYTIN');
    });

    test('localizes the name, falling back to French', () {
      final b = build();
      expect(b.nomLocalise('en'), 'Late blight');
      expect(b.nomLocalise('es'), 'Mildiou');
    });

    test('returns the French description as fallback, null when absent', () {
      expect(build().descriptionLocalisee('en'), 'Maladie cryptogamique.');
      final sans = Bioagresseur(
        id: 'puceron',
        type: TypeBioagresseur.ravageur,
        nomsLocalises: const {'fr': 'Puceron'},
      );
      expect(sans.descriptionLocalisee('fr'), isNull);
      expect(sans.codeEppo, isNull);
    });

    test('stores collections unmodifiable', () {
      expect(() => build().nomsLocalises['de'] = 'x', throwsUnsupportedError);
    });

    test('equality is by id', () {
      final autre = Bioagresseur(
        id: 'mildiou',
        type: TypeBioagresseur.ravageur,
        nomsLocalises: const {'fr': 'Autre'},
      );
      expect(build(), equals(autre));
      expect(build().hashCode, autre.hashCode);
    });
  });
}
