import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_cache.dart';
import 'package:pot_a_gerer/infrastructure/repositories/fiche_plante_repository_impl.dart';

FichePlante _fiche(
  String id,
  CategoriePlante categorie,
  Set<UsagePlante> usages,
  String nomFr,
) =>
    FichePlante(
      id: id,
      nomScientifique: 'X x',
      familleBotanique: 'Xaceae',
      categorie: categorie,
      usages: usages,
      nomsLocalises: {'fr': nomFr},
      besoins: BesoinsCulture(
        eau: BesoinEau.modere,
        soleil: NiveauSoleil.pleinSoleil,
        phMin: 6,
        phMax: 7,
      ),
      espacementCm: 30,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 80,
    );

void main() {
  final tomate =
      _fiche('tomate', CategoriePlante.legume, {UsagePlante.alimentaire}, 'Tomate');
  final souci = _fiche('souci', CategoriePlante.fleur,
      {UsagePlante.compagnonnage, UsagePlante.ornementale}, 'Souci');
  final cache = FichePlanteCache([tomate, souci]);

  group('FichePlanteCache', () {
    test('indexes by id', () {
      expect(cache.nombre, 2);
      expect(cache.parId('tomate'), tomate);
      expect(cache.parId('inconnu'), isNull);
    });

    test('filters by category and usage', () {
      expect(cache.parCategorie(CategoriePlante.legume), [tomate]);
      expect(cache.parUsage(UsagePlante.compagnonnage), [souci]);
    });

    test('search matches localized name or id (case-insensitive)', () {
      expect(cache.rechercher('tom', 'fr'), [tomate]);
      expect(cache.rechercher('SOUCI', 'fr'), [souci]);
      expect(cache.rechercher('', 'fr'), hasLength(2));
    });

    test('last sheet wins on duplicate id', () {
      final perso = _fiche(
          'tomate', CategoriePlante.legume, {UsagePlante.alimentaire}, 'Ma tomate');
      final c = FichePlanteCache([tomate, perso]);
      expect(c.nombre, 1);
      expect(c.parId('tomate')!.nomLocalise('fr'), 'Ma tomate');
    });
  });

  group('FichePlanteRepositoryImpl', () {
    final repo = FichePlanteRepositoryImpl(cache);

    test('serves queries from the cache', () async {
      expect(await repo.obtenirToutes(), hasLength(2));
      expect(await repo.obtenirParId('souci'), souci);
      expect(
          await repo.filtrerParCategorie(CategoriePlante.fleur), [souci]);
      expect(await repo.filtrerParUsage(UsagePlante.alimentaire), [tomate]);
      expect(await repo.rechercher('tom', 'fr'), [tomate]);
    });
  });
}
