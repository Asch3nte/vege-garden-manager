import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/catalogue_notifier.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

void main() {
  late MockFiches fiches;

  FichePlante fiche(String id, String nomFr, CategoriePlante cat) =>
      FichePlante(
        id: id,
        nomScientifique: '$id sp',
        familleBotanique: 'Test',
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
    catalogue = [
      fiche('tomate', 'Tomate', CategoriePlante.legume),
      fiche('basilic', 'Basilic', CategoriePlante.aromatique),
      fiche('courgette', 'Courgette', CategoriePlante.legume),
      fiche('fraise', 'Fraise', CategoriePlante.petitFruit),
    ];
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => catalogue);
  });

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
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
    expect(vue.total, 4, reason: 'total stays the full catalogue size');
  });
}
