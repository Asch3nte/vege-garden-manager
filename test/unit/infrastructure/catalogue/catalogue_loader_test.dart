import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/catalogue_loader.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_asset_source.dart';

/// In-memory [FicheAssetSource] for tests.
class _FakeSource implements FicheAssetSource {
  final Map<String, String> fiches;
  _FakeSource(this.fiches);

  @override
  Future<List<String>> listerCheminsFiches() async => fiches.keys.toList();

  @override
  Future<String> lireFiche(String chemin) async => fiches[chemin]!;
}

const _ficheInvalide = '''
id: cassee
categorie: legume
usages: [alimentaire]
# manque nom_scientifique, i18n, besoins, cycle...
''';

/// A complete, standalone mother sheet (species level).
const _mere = '''
id: LEG-001
nom_scientifique: Solanum lycopersicum
famille_botanique: Solanaceae
categorie: legume
usages: [alimentaire]
i18n:
  fr:
    nom_commun: Tomate
besoins:
  ensoleillement: plein_soleil
  arrosage: eleve
  qualites_sol: [riche]
  ph_min: 6.0
  ph_max: 7.0
cycle:
  espacement_cm: 60
  duree_avant_recolte_jours: [70, 90]
''';

/// A variety sheet declaring only its differences from [_mere]. It even tries
/// (illegally) to override the species-level `categorie`.
const _fille = '''
id: LEG-001-V001
parent_id: LEG-001
categorie: fleur
i18n:
  fr:
    nom_commun: Cœur de Bœuf
cycle:
  espacement_cm: 80
''';

/// A variety whose parent does not exist in the catalogue.
const _filleOrpheline = '''
id: LEG-999-V001
parent_id: LEG-999
i18n:
  fr:
    nom_commun: Orpheline
''';

void main() {
  final golden =
      File('assets/fiches_plantes/legumes/LEG-001.yaml').readAsStringSync();

  test('loads valid sheets and skips a corrupt one (reported, not fatal)',
      () async {
    final erreurs = <String>[];
    final source = _FakeSource({
      'legumes/LEG-001.yaml': golden,
      'legumes/cassee.yaml': _ficheInvalide,
    });
    final loader = CatalogueLoader(
      source,
      (chemin, erreur) => erreurs.add(chemin),
    );

    final cache = await loader.charger();

    expect(cache.nombre, 1);
    expect(cache.parId('LEG-001'), isNotNull);
    expect(erreurs, ['legumes/cassee.yaml']);
  });

  test('an all-invalid catalogue yields an empty cache without throwing',
      () async {
    final source = _FakeSource({'a.yaml': _ficheInvalide, 'b.yaml': 'not: [a, map'});
    final cache = await CatalogueLoader(source).charger();
    expect(cache.nombre, 0);
  });

  group('species/variety inheritance (ADR-0005)', () {
    test('a variety inherits its mother and overrides only its own fields',
        () async {
      // The variety is listed before its mother to prove order does not matter
      // (resolution happens in a second pass).
      final source = _FakeSource({
        'legumes/LEG-001-V001.yaml': _fille,
        'legumes/LEG-001.yaml': _mere,
      });
      final cache = await CatalogueLoader(source).charger();

      expect(cache.nombre, 2);
      final variete = cache.parId('LEG-001-V001')!;
      expect(variete.parentId, 'LEG-001');
      expect(variete.estVariete, isTrue);
      expect(variete.nomLocalise('fr'), 'Cœur de Bœuf');
      expect(variete.espacementCm, 80); // overridden
      expect(variete.besoins.phMin, 6.0); // inherited
      // `categorie` is non-overridable: forced from the mother.
      expect(variete.categorie, CategoriePlante.legume);

      expect(cache.meres().map((f) => f.id), ['LEG-001']);
      expect(cache.varietesDe('LEG-001').map((f) => f.id), ['LEG-001-V001']);
    });

    test('an orphan variety is reported and skipped, never fatal', () async {
      final erreurs = <String>[];
      final source = _FakeSource({
        'legumes/LEG-001.yaml': _mere,
        'legumes/orpheline.yaml': _filleOrpheline,
      });
      final cache = await CatalogueLoader(
        source,
        (chemin, erreur) => erreurs.add(chemin),
      ).charger();

      expect(cache.nombre, 1);
      expect(cache.parId('LEG-001'), isNotNull);
      expect(erreurs, ['legumes/orpheline.yaml']);
    });
  });
}
