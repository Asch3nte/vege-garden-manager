import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/horloge_provider.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/potager_notifier.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/entities/tache.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/cible_tache.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_tache.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_tache_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockTaches extends Mock implements AbstractTacheRepository {}

void main() {
  final maintenant = DateTime(2026, 6, 9, 8, 24);

  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockFiches fiches;
  late MockTaches taches;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    fiches = MockFiches();
    taches = MockTaches();
    // Default: no task today.
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => []);
  });

  Potager unPotager() => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
      );

  Plantation unePlantation(String id, String planteId, StatutPlantation statut) =>
      Plantation(
        id: id,
        planteId: planteId,
        parcelleId: 'z-1',
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 3,
        statut: statut,
        // Invariant: a terminal status iff an end date is present.
        dateFinReelle:
            statut == StatutPlantation.enCours ? null : DateTime(2026, 6, 1),
      );

  Parcelle uneParcelle(String id, String nom, List<Plantation> plantations) =>
      Parcelle(
        id: id,
        nom: nom,
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
        plantations: plantations,
      );

  FichePlante uneFiche(String id, String nomFr) => FichePlante(
        id: id,
        nomScientifique: '$id sp',
        familleBotanique: 'Test',
        categorie: CategoriePlante.legume,
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

  Tache uneTacheParcelle(String parcelleId) => Tache(
        id: 't-$parcelleId',
        titre: 'Arroser',
        type: TypeTache.arrosage,
        cible: CibleTache.parcelle,
        cibleId: parcelleId,
        datePrevue: maintenant,
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(potagers),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      tacheRepositoryProvider.overrideWithValue(taches),
      fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
      horlogeProvider.overrideWithValue(() => maintenant),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('lists zones with active crop names resolved from the catalogue',
      () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        uneParcelle('z-1', 'Carré nord', [
          unePlantation('p-1', 'tomate', StatutPlantation.enCours),
          unePlantation('p-2', 'basilic', StatutPlantation.enCours),
        ]),
      ],
    );
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));
    when(() => fiches.obtenirParId('basilic'))
        .thenAnswer((_) async => uneFiche('basilic', 'Basilic'));

    final vue = await conteneur().read(potagerProvider.future);

    expect(vue.nomPotager, 'Mon potager');
    expect(vue.zones, hasLength(1));
    expect(vue.zones.single.cultures, ['Tomate', 'Basilic']);
    expect(vue.zones.single.surfaceM2, 2);
    expect(vue.zones.single.exposition, NiveauSoleil.pleinSoleil);
  });

  test('terminal plantations are excluded from a zone\'s crops', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        uneParcelle('z-1', 'Carré nord', [
          unePlantation('p-1', 'tomate', StatutPlantation.enCours),
          unePlantation('p-2', 'radis', StatutPlantation.recoltee),
        ]),
      ],
    );
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));

    final vue = await conteneur().read(potagerProvider.future);

    expect(vue.zones.single.cultures, ['Tomate']);
    verifyNever(() => fiches.obtenirParId('radis'));
  });

  test('a missing fiche degrades to a skipped crop, not an error', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        uneParcelle('z-1', 'Carré nord', [
          unePlantation('p-1', 'inconnu', StatutPlantation.enCours),
          unePlantation('p-2', 'tomate', StatutPlantation.enCours),
        ]),
      ],
    );
    when(() => fiches.obtenirParId('inconnu')).thenAnswer((_) async => null);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));

    final vue = await conteneur().read(potagerProvider.future);

    expect(vue.zones.single.cultures, ['Tomate']);
  });

  test('flags zones that have a task due today', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1')).thenAnswer(
      (_) async => [
        uneParcelle('z-1', 'Avec tâche', []),
        uneParcelle('z-2', 'Sans tâche', []),
      ],
    );
    when(() => taches.obtenirEntreDates(any(), any()))
        .thenAnswer((_) async => [uneTacheParcelle('z-1')]);

    final vue = await conteneur().read(potagerProvider.future);

    expect(vue.zones[0].aTacheAujourdhui, isTrue);
    expect(vue.zones[1].aTacheAujourdhui, isFalse);
  });

  test('no active garden → empty view', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);

    final vue = await conteneur().read(potagerProvider.future);

    expect(vue.nomPotager, isNull);
    expect(vue.zones, isEmpty);
    expect(vue.estVide, isTrue);
    verifyNever(() => parcelles.obtenirParPotager(any()));
  });
}
