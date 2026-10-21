import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fusionneur_fiches.dart';

/// Value at [cle] of the mapping found at [section] of [m].
Object? champ(Map<dynamic, dynamic> m, String section, String cle) =>
    (m[section] as Map<dynamic, dynamic>)[cle];

void main() {
  const fusionneur = FusionneurFiches();

  Map<dynamic, dynamic> mere() => {
        'id': 'LEG-001',
        'categorie': 'legume',
        'sous_type': 'legume_fruit',
        'nom_scientifique': 'Solanum lycopersicum',
        'famille_botanique': 'Solanaceae',
        'usages': ['alimentaire'],
        'i18n': {
          'fr': {'nom_commun': 'Tomate', 'description': 'Espèce.'},
        },
        'besoins': {'arrosage': 'eleve', 'temperature_optimale': 22},
        'cycle': {'espacement_cm': 60, 'duree_avant_recolte_jours': [70, 90]},
        'rotation': {'famille': 'solanaceae', 'delai_retour_annees': 4},
        'associations': {
          'beneficies': [
            {'id': 'ARO-001'},
          ],
        },
      };

  group('FusionneurFiches', () {
    test('inherits every field the variety does not declare', () {
      final fusion = fusionneur.fusionner(mere(), {
        'id': 'LEG-001-V001',
        'parent_id': 'LEG-001',
        'i18n': {
          'fr': {'nom_commun': 'Cœur de Bœuf'},
        },
      });

      // Own fields kept.
      expect(fusion['id'], 'LEG-001-V001');
      expect(fusion['parent_id'], 'LEG-001');
      // Inherited verbatim.
      expect(champ(fusion, 'cycle', 'espacement_cm'), 60);
      expect(champ(fusion, 'besoins', 'temperature_optimale'), 22);
    });

    test('deep-merges nested mappings (overrides one sub-field, keeps siblings)',
        () {
      final fusion = fusionneur.fusionner(mere(), {
        'id': 'LEG-001-V001',
        'parent_id': 'LEG-001',
        'besoins': {'temperature_optimale': 24},
      });

      // Overridden, sibling preserved.
      expect(champ(fusion, 'besoins', 'temperature_optimale'), 24);
      expect(champ(fusion, 'besoins', 'arrosage'), 'eleve');
    });

    test('forces non-overridable fields from the mother', () {
      final fusion = fusionneur.fusionner(mere(), {
        'id': 'LEG-001-V001',
        'parent_id': 'LEG-001',
        // The variety tries (illegally) to override species-level fields.
        'categorie': 'aromatique',
        'usages': ['ornementale'],
        'rotation': {'famille': 'autre'},
        'associations': {'beneficies': []},
      });

      expect(fusion['categorie'], 'legume');
      expect(fusion['usages'], ['alimentaire']);
      expect(champ(fusion, 'rotation', 'famille'), 'solanaceae');
      expect(champ(fusion, 'associations', 'beneficies') as List, hasLength(1));
    });

    test('the merged map is mutable (plain Map/List, not Yaml nodes)', () {
      final fusion = fusionneur.fusionner(mere(), {
        'id': 'LEG-001-V001',
        'parent_id': 'LEG-001',
      });
      expect(() => (fusion['besoins'] as Map)['x'] = 1, returnsNormally);
    });
  });
}
