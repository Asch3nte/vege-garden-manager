import 'package:flutter_test/flutter_test.dart';

import '../../../../bin/migrer_ids.dart';

void main() {
  group('migrerContenu — id rewriting', () {
    test('rewrites a mother id and preserves the trailing comment', () {
      const yaml = 'id: carotte # unique, immuable\nversion_fiche: 1\n';
      final out = migrerContenu(yaml);
      expect(out, contains('id: LEG-004 # unique, immuable'));
      expect(out, isNot(contains('parent_id:'))); // a mother has none
    });

    test('rewrites a variety id and inserts its parent_id', () {
      const yaml = 'id: carotte_nantaise_amelioree\nversion_fiche: 1\n';
      final out = migrerContenu(yaml);
      final lignes = out.split('\n');
      expect(lignes[0], 'id: LEG-004-V001');
      expect(lignes[1], 'parent_id: LEG-004');
    });

    test('leaves a sheet whose id is unknown untouched', () {
      const yaml = 'id: inconnu_xyz\nfoo: bar\n';
      expect(migrerContenu(yaml), yaml);
    });
  });

  group('migrerContenu — association refs', () {
    const yaml = '''
id: carotte
associations:
  beneficies:
    - id: poireau
      raison_i18n: { fr: "x", en: "y" }
    - id: laitue
  defavorables:
    - id: aneth
''';

    test('rewrites known refs to their mother id', () {
      final out = migrerContenu(yaml);
      expect(out, contains('- id: LEG-017')); // poireau
      expect(out, contains('- id: LEG-014')); // laitue
    });

    test('leaves a ref with no fiche untouched', () {
      expect(migrerContenu(yaml), contains('- id: aneth'));
    });

    test('does not treat the top-level id as an association ref', () {
      // The top-level `id:` is rewritten via tableFiches, never tableRefs.
      expect(migrerContenu(yaml), contains('id: LEG-004'));
    });
  });

  group('nouveauNomFichier', () {
    test('maps a legacy file name to its canonical name', () {
      expect(nouveauNomFichier('assets/fiches_plantes/legumes/carotte.yaml'),
          'LEG-004.yaml');
      expect(
          nouveauNomFichier(
              'assets/fiches_plantes/legumes/tomate_coeur_de_boeuf.yaml'),
          'LEG-001-V001.yaml');
    });

    test('returns null for an unknown file', () {
      expect(nouveauNomFichier('assets/fiches_plantes/legumes/inconnu.yaml'),
          isNull);
    });
  });
}
