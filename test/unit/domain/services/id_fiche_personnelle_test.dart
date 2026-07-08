import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/services/id_fiche_personnelle.dart';

void main() {
  test('prefixes every id and slugifies the name', () {
    expect(IdFichePersonnelle.depuisNom('Tomate'), 'perso_tomate');
  });

  test('folds French accents and collapses separators', () {
    expect(IdFichePersonnelle.depuisNom('Tomate de mémé'),
        'perso_tomate_de_meme');
    expect(IdFichePersonnelle.depuisNom('Cœur de bœuf'),
        'perso_coeur_de_boeuf');
    expect(IdFichePersonnelle.depuisNom('Piment  —  fort !'),
        'perso_piment_fort');
  });

  test('trims leading and trailing separators', () {
    expect(IdFichePersonnelle.depuisNom('  Basilic  '), 'perso_basilic');
    expect(IdFichePersonnelle.depuisNom('"Menthe"'), 'perso_menthe');
  });

  test('falls back to a stable id for an empty slug', () {
    expect(IdFichePersonnelle.depuisNom('   '), 'perso_fiche');
    expect(IdFichePersonnelle.depuisNom('!!!'), 'perso_fiche');
  });

  test('never collides with the built-in canonical id format', () {
    // Built-ins are LEG-001 etc.; personal ids are always prefixed.
    expect(IdFichePersonnelle.depuisNom('LEG-001').startsWith('perso_'),
        isTrue);
  });
}
