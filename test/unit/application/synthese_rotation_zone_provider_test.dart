import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/synthese_rotation_zone_provider.dart';
import 'package:pot_a_gerer/domain/entities/famille_botanique.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/famille_botanique_cache.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:riverpod/riverpod.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

FichePlante _fiche(
  String id,
  String famille, {
  int? delaiRetour,
  bool fixeAzote = false,
  CategoriePlante categorie = CategoriePlante.legume,
}) =>
    FichePlante(
      id: id,
      nomScientifique: '$id sp',
      familleBotanique: famille,
      rotationFamille: famille,
      categorie: categorie,
      usages: const {UsagePlante.alimentaire},
      nomsLocalises: {'fr': id},
      besoins: BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 7),
      espacementCm: 30,
      dureeAvantRecolteJoursMin: 60,
      dureeAvantRecolteJoursMax: 80,
      delaiRetourAnnees: delaiRetour,
      fixeAzote: fixeAzote,
    );

Plantation _plant(String id, String planteId, DateTime fin) => Plantation(
      id: id,
      planteId: planteId,
      parcelleId: 'z1',
      dateMiseEnPlace: DateTime.utc(fin.year, 3, 1),
      methode: MethodeMiseEnPlace.plantAchete,
      surfaceOccupee: Surface.enMetresCarres(0.5),
      nombrePieds: 1,
      statut: StatutPlantation.recoltee,
      dateFinReelle: fin,
    );

FamilleBotanique _famille(String id, String nomFr) => FamilleBotanique(
      id: id,
      nomScientifique: id[0].toUpperCase() + id.substring(1),
      categories: const {CategoriePlante.legume},
      nomsLocalises: {'fr': nomFr},
    );

void main() {
  final maintenant = DateTime.utc(2026, 6, 15);

  final catalogue = [
    _fiche('tomate', 'solanaceae', delaiRetour: 4),
    _fiche('pois', 'fabaceae', delaiRetour: 3, fixeAzote: true),
  ];
  final familles = FamilleBotaniqueCache([
    _famille('solanaceae', 'Solanacées'),
    _famille('fabaceae', 'Fabacées'),
  ]);

  ProviderContainer conteneur(List<Plantation> plantations) {
    final fiches = MockFiches();
    final plants = MockPlantations();
    when(fiches.obtenirToutes).thenAnswer((_) async => catalogue);
    when(() => plants.obtenirParParcelle('z1'))
        .thenAnswer((_) async => plantations);
    return ProviderContainer(overrides: [
      fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
      familleBotaniqueCacheProvider.overrideWith((ref) async => familles),
      plantationRepositoryProvider.overrideWithValue(plants),
      horlogeProvider.overrideWithValue(() => maintenant),
    ]);
  }

  Future<SyntheseRotationZone> lire(
    List<Plantation> plantations, {
    TypeParcelle type = TypeParcelle.pleineTerre,
  }) async {
    final c = conteneur(plantations);
    addTearDown(c.dispose);
    return c.read(
        syntheseRotationZoneProvider((zoneId: 'z1', type: type)).future);
  }

  test('a renewable-soil container is not applicable (nothing to show)',
      () async {
    final s = await lire(
      [_plant('p1', 'tomate', DateTime.utc(2025, 8, 1))],
      type: TypeParcelle.pot,
    );
    expect(s.applicable, isFalse);
    expect(s.aQuelqueChose, isFalse);
  });

  test('an empty plot yields nothing', () async {
    final s = await lire(const []);
    expect(s.aQuelqueChose, isFalse);
  });

  test('a recently grown family shows up with its French name and year',
      () async {
    final s = await lire([_plant('p1', 'tomate', DateTime.utc(2025, 8, 1))]);
    expect(s.recentes, hasLength(1));
    expect(s.recentes.single.nomFamille, 'Solanacées');
    expect(s.recentes.single.nomPlante, 'tomate');
    expect(s.recentes.single.annee, 2025);
  });

  test('a family within its return delay is blocked until year+delay',
      () async {
    final s = await lire([_plant('p1', 'tomate', DateTime.utc(2025, 8, 1))]);
    expect(s.famillesBloquees, hasLength(1));
    final b = s.famillesBloquees.single;
    expect(b.familleSlug, 'solanaceae');
    expect(b.nomFamille, 'Solanacées');
    expect(b.delaiAnnees, 4);
    expect(b.anneeLibre, 2029); // 2025 + 4
  });

  test('a family grown beyond its delay is not blocked', () async {
    final s = await lire([_plant('p1', 'tomate', DateTime.utc(2020, 8, 1))]);
    expect(s.famillesBloquees, isEmpty);
  });

  test('a recent nitrogen fixer surfaces a nitrogen opportunity', () async {
    final s = await lire([_plant('p1', 'pois', DateTime.utc(2025, 8, 1))]);
    expect(s.opportunites, hasLength(1));
    expect(s.opportunites.single.nomPlante, 'pois');
  });

  test('an unknown planted id is skipped, never invents a family', () async {
    final s = await lire([_plant('p1', 'inconnue', DateTime.utc(2025, 8, 1))]);
    expect(s.aQuelqueChose, isFalse);
  });
}
