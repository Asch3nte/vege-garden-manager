// Unit tests for the Saison view-model: cultivated plants and their windows,
// resolved for the active garden's hemisphere × climate.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:pot_a_gerer/application/providers/repository_providers.dart';
import 'package:pot_a_gerer/application/state/saison_notifier.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/entities/potager.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_potager_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockPotagers extends Mock implements AbstractPotagerRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

void main() {
  late MockPotagers potagers;
  late MockParcelles parcelles;
  late MockPlantations plantations;
  late MockFiches fiches;

  setUp(() {
    potagers = MockPotagers();
    parcelles = MockParcelles();
    plantations = MockPlantations();
    fiches = MockFiches();
    when(() => parcelles.obtenirParPotager(any())).thenAnswer((_) async => []);
    when(() => plantations.obtenirParParcelle(any())).thenAnswer((_) async => []);
  });

  Potager unPotager({Localisation? localisation}) => Potager(
        id: 'pot-1',
        nom: 'Mon potager',
        zoneClimatique:
            const ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8),
        dateCreation: DateTime(2026, 1, 1),
        localisation: localisation ?? const Localisation.nonDefinie(),
      );

  Parcelle uneParcelle(String id) => Parcelle(
        id: id,
        nom: 'Zone $id',
        potagerId: 'pot-1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      );

  Plantation unePlantation(String planteId, String parcelleId) => Plantation(
        id: 'p-$planteId',
        planteId: planteId,
        parcelleId: parcelleId,
        dateMiseEnPlace: DateTime(2026, 4, 1),
        methode: MethodeMiseEnPlace.semisDirect,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 3,
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
        periodes: const {
          Hemisphere.nord: {
            TypeClimat.oceanique: PeriodesCulture(
              semisExterieur: Periode(3, 5),
              plantation: Periode(4, 5),
              recolte: Periode(7, 9),
            ),
          },
        },
      );

  ProviderContainer conteneur() {
    final c = ProviderContainer(overrides: [
      potagerRepositoryProvider.overrideWithValue(potagers),
      parcelleRepositoryProvider.overrideWithValue(parcelles),
      plantationRepositoryProvider.overrideWithValue(plantations),
      fichePlanteRepositoryProvider.overrideWith((ref) async => fiches),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('no active garden → no context', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer((_) async => null);

    final vue = await conteneur().read(saisonProvider.future);

    expect(vue.contexteConnu, isFalse);
  });

  test('charts cultivated plants and assumes north when no position', () async {
    when(() => potagers.obtenirPotagerActif())
        .thenAnswer((_) async => unPotager());
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1')]);
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('tomate', 'z-1')]);
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));

    final vue = await conteneur().read(saisonProvider.future);

    expect(vue.contexteConnu, isTrue);
    expect(vue.hemisphereSuppose, isTrue); // no position set
    expect(vue.lignes, hasLength(1));
    final ligne = vue.lignes.single;
    expect(ligne.nom, 'Tomate');
    expect(ligne.semis, const Periode(3, 5));
    expect(ligne.plantation, const Periode(4, 5));
    expect(ligne.recolte, const Periode(7, 9));
  });

  test('a southern latitude derives the southern hemisphere', () async {
    when(() => potagers.obtenirPotagerActif()).thenAnswer(
      (_) async => unPotager(
        localisation: Localisation.gps(latitude: -33.9, longitude: 18.4),
      ),
    );
    when(() => parcelles.obtenirParPotager('pot-1'))
        .thenAnswer((_) async => [uneParcelle('z-1')]);
    when(() => plantations.obtenirParParcelle('z-1'))
        .thenAnswer((_) async => [unePlantation('tomate', 'z-1')]);
    // The fiche only has northern periods, so the southern windows are empty.
    when(() => fiches.obtenirParId('tomate'))
        .thenAnswer((_) async => uneFiche('tomate', 'Tomate'));

    final vue = await conteneur().read(saisonProvider.future);

    expect(vue.hemisphereSuppose, isFalse);
    expect(vue.lignes.single.aDesDonnees, isFalse);
  });
}
