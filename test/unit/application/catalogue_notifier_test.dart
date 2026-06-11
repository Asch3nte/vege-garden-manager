import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/catalogue_notifier.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_famille_botanique_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockFamilles extends Mock implements AbstractFamilleBotaniqueRepository {}

FamilleBotanique famille(String id, String nomFr, Set<CategoriePlante> cats) =>
    FamilleBotanique(
      id: id,
      nomScientifique: id[0].toUpperCase() + id.substring(1),
      categories: cats,
      nomsLocalises: {'fr': nomFr},
    );

void main() {
  late MockFiches fiches;
  late MockFamilles familles;

  FichePlante fiche(String id, String nomFr, CategoriePlante cat,
          {String? parentId, String famille = 'Test'}) =>
      FichePlante(
        id: id,
        parentId: parentId,
        nomScientifique: '$id sp',
        familleBotanique: famille,
        categorie: cat,
        usages: const {UsagePlante.alimentaire},
        nomsLocalises: {'fr': nomFr},
        besoins: BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 7,
        ),
        espacementCm: 40,
        dureeAvantRecolteJoursMin: 60,
        dureeAvantRecolteJoursMax: 80,
        periodes: const {},
      );

  late List<FichePlante> catalogue;

  setUp(() {
    fiches = MockFiches();
    familles = MockFamilles();
    catalogue = [
      fiche('tomate', 'Tomate', CategoriePlante.legume, famille: 'Solanaceae'),
      fiche('tomate-v1', 'Tomate Cerise', CategoriePlante.legume,
          parentId: 'tomate', famille: 'Solanaceae'),
      fiche('basilic', 'Basilic', CategoriePlante.aromatique,
          famille: 'Lamiaceae'),
      fiche('courgette', 'Courgette', CategoriePlante.legume,
          famille: 'Cucurbitaceae'),
      fiche('fraise', 'Fraise', CategoriePlante.petitFruit,
          famille: 'Rosaceae'),
    ];
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => catalogue);
    when(() => familles.obtenirToutes()).thenAnswer((_) async => [
          famille('solanaceae', 'Solanacées', {CategoriePlante.legume}),
          famille('cucurbitaceae', 'Cucurbitacées', {CategoriePlante.legume}),
          famille('lamiaceae', 'Lamiacées', {CategoriePlante.aromatique}),
          famille('rosaceae', 'Rosacées', {CategoriePlante.petitFruit}),
        ]);
  });

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
      familleBotaniqueRepositoryProvider.overrideWith((ref) async => familles),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('loads the whole catalogue, ordered by name', () async {
    final c = conteneur();
    final vue = await c.read(catalogueProvider.future);

    expect(vue.total, 4);
    expect(vue.nombreResultats, 4);
    expect(
      vue.fiches.map((f) => f.nomLocalise('fr')),
      ['Basilic', 'Courgette', 'Fraise', 'Tomate'],
    );
    expect(vue.filtreActif, isFalse);
  });

  test('filters by category', () async {
    final c = conteneur();
    await c.read(catalogueProvider.future);

    c.read(catalogueProvider.notifier).definirCategorie(CategoriePlante.legume);
    final vue = c.read(catalogueProvider).value!;

    expect(vue.fiches.map((f) => f.id), ['courgette', 'tomate']);
    expect(vue.categorie, CategoriePlante.legume);
    expect(vue.filtreActif, isTrue);
  });

  test('filters by query (case-insensitive, on the localized name)', () async {
    final c = conteneur();
    await c.read(catalogueProvider.future);

    c.read(catalogueProvider.notifier).definirRequete('TOM');
    final vue = c.read(catalogueProvider).value!;

    expect(vue.fiches.map((f) => f.id), ['tomate']);
  });

  test('combines query and category', () async {
    final c = conteneur();
    await c.read(catalogueProvider.future);

    c.read(catalogueProvider.notifier)
      ..definirCategorie(CategoriePlante.legume)
      ..definirRequete('cour');
    final vue = c.read(catalogueProvider).value!;

    expect(vue.fiches.map((f) => f.id), ['courgette']);
  });

  test('no match → empty result flagged', () async {
    final c = conteneur();
    await c.read(catalogueProvider.future);

    c.read(catalogueProvider.notifier).definirRequete('zzz');
    final vue = c.read(catalogueProvider).value!;

    expect(vue.sansResultat, isTrue);
    expect(vue.total, 4, reason: 'total stays the species count');
  });

  test('groups varieties under their species; counts only species', () async {
    final c = conteneur();
    final vue = await c.read(catalogueProvider.future);

    // Species only (variety excluded from the count and the network list).
    expect(vue.total, 4);
    expect(vue.toutesMeres.every((f) => f.estMere), isTrue);
    expect(vue.toutesMeres.map((f) => f.id), isNot(contains('tomate-v1')));

    final tomate = vue.groupes.firstWhere((g) => g.mere.id == 'tomate');
    expect(tomate.varietes.map((f) => f.id), ['tomate-v1']);
    expect(vue.groupes.firstWhere((g) => g.mere.id == 'basilic').aVarietes,
        isFalse);
  });

  test('searching a variety name surfaces its species', () async {
    final c = conteneur();
    await c.read(catalogueProvider.future);

    c.read(catalogueProvider.notifier).definirRequete('cerise');
    final vue = c.read(catalogueProvider).value!;

    expect(vue.groupes, hasLength(1));
    expect(vue.groupes.single.mere.id, 'tomate');
    expect(vue.groupes.single.varietes.map((f) => f.id), ['tomate-v1']);
  });

  group('family sub-filter (ADR-0006)', () {
    test('no family chips under "Tout"', () async {
      final c = conteneur();
      final vue = await c.read(catalogueProvider.future);
      expect(vue.familles, isEmpty);
      expect(vue.familleSelectionnee, isNull);
    });

    test('derives the families present in the selected category, by name',
        () async {
      final c = conteneur();
      await c.read(catalogueProvider.future);

      c.read(catalogueProvider.notifier).definirCategorie(CategoriePlante.legume);
      final vue = c.read(catalogueProvider).value!;

      // Only families with a species in "legume", ordered by localized name.
      expect(vue.familles.map((f) => f.id), ['cucurbitaceae', 'solanaceae']);
    });

    test('filters the list by the selected family', () async {
      final c = conteneur();
      await c.read(catalogueProvider.future);

      c.read(catalogueProvider.notifier)
        ..definirCategorie(CategoriePlante.legume)
        ..definirFamille('solanaceae');
      final vue = c.read(catalogueProvider).value!;

      expect(vue.fiches.map((f) => f.id), ['tomate']);
      expect(vue.familleSelectionnee, 'solanaceae');
      expect(vue.filtreActif, isTrue);
    });

    test('changing category clears the family sub-filter', () async {
      final c = conteneur();
      await c.read(catalogueProvider.future);

      c.read(catalogueProvider.notifier)
        ..definirCategorie(CategoriePlante.legume)
        ..definirFamille('solanaceae');
      expect(c.read(catalogueProvider).value!.familleSelectionnee, 'solanaceae');

      c.read(catalogueProvider.notifier)
          .definirCategorie(CategoriePlante.aromatique);
      final vue = c.read(catalogueProvider).value!;
      expect(vue.familleSelectionnee, isNull);
      expect(vue.fiches.map((f) => f.id), ['basilic']);
    });
  });
}
