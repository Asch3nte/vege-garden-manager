import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/engine/bilan_arrosage.dart';
import 'package:pot_a_gerer/application/use_cases/calculer_besoin_arrosage.dart';
import 'package:pot_a_gerer/domain/entities/equipement.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/type_equipement.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/type_releve_meteo.dart';
import 'package:pot_a_gerer/domain/enums/urgence_arrosage.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/exceptions/meteo_indisponible_exception.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_equipement_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_meteo_service.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_parcelle_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/prevision_meteo.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockParcelles extends Mock implements AbstractParcelleRepository {}

class MockEquipements extends Mock implements AbstractEquipementRepository {}

class MockMeteo extends Mock implements AbstractMeteoService {}

void main() {
  final loc =
      Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);

  final tomate = FichePlante(
    id: 'tomate',
    nomScientifique: 'Solanum lycopersicum',
    familleBotanique: 'Solanaceae',
    categorie: CategoriePlante.legume,
    usages: const {UsagePlante.alimentaire},
    nomsLocalises: const {'fr': 'Tomate'},
    besoins: BesoinsCulture(
      eau: BesoinEau.eleve,
      soleil: NiveauSoleil.pleinSoleil,
      phMin: 6,
      phMax: 7,
    ),
    espacementCm: 60,
    dureeAvantRecolteJoursMin: 70,
    dureeAvantRecolteJoursMax: 90,
  );

  Parcelle parcelle() => Parcelle(
        id: 'par1',
        nom: 'Bac',
        potagerId: 'pot1',
        type: TypeParcelle.bacSureleve,
        surface: Surface.enMetresCarres(2),
        exposition: NiveauSoleil.pleinSoleil,
      );

  final plantation = Plantation(
    id: 'pl1',
    planteId: 'tomate',
    parcelleId: 'par1',
    dateMiseEnPlace: DateTime.utc(2026, 5, 1),
    methode: MethodeMiseEnPlace.repiquage,
    surfaceOccupee: Surface.enMetresCarres(1),
    nombrePieds: 2,
  );

  List<PrevisionMeteo> fenetre({List<double> futurPrecip = const [0, 0, 0]}) {
    return [
      for (var i = 5; i >= 1; i--)
        PrevisionMeteo(
          date: DateTime.utc(2026, 5, 31).subtract(Duration(days: i)),
          tempMin: 12,
          tempMax: 22,
          precipitationsMm: 0,
          type: TypeReleveMeteo.observe,
        ),
      for (var i = 0; i < futurPrecip.length; i++)
        PrevisionMeteo(
          date: DateTime.utc(2026, 6, 1).add(Duration(days: i)),
          tempMin: 14,
          tempMax: 26,
          precipitationsMm: futurPrecip[i],
          type: TypeReleveMeteo.prevu,
        ),
    ];
  }

  late MockFiches fiches;
  late MockParcelles parcelles;
  late MockEquipements equipements;
  late MockMeteo meteo;
  late CalculerBesoinArrosage useCase;

  setUp(() {
    fiches = MockFiches();
    parcelles = MockParcelles();
    equipements = MockEquipements();
    meteo = MockMeteo();
    useCase = CalculerBesoinArrosage(
        fiches, parcelles, equipements, meteo, const BilanArrosage());

    when(() => fiches.obtenirParId('tomate')).thenAnswer((_) async => tomate);
    when(() => parcelles.obtenirParId('par1'))
        .thenAnswer((_) async => parcelle());
    when(() => equipements.obtenirParParcelle('par1'))
        .thenAnswer((_) async => const []);
  });

  test('high-need plant on dry weather -> water now', () async {
    when(() => meteo.obtenirPrevisions(loc, 3, joursPasses: 5))
        .thenAnswer((_) async => fenetre());

    final c = await useCase.executer(plantation: plantation, localisation: loc);
    expect(c, isNotNull);
    expect(c!.urgence, UrgenceArrosage.arroserMaintenant);
  });

  test('forecast rain defers watering', () async {
    when(() => meteo.obtenirPrevisions(loc, 3, joursPasses: 5))
        .thenAnswer((_) async => fenetre(futurPrecip: [0, 20, 0]));

    final c = await useCase.executer(plantation: plantation, localisation: loc);
    expect(c!.urgence, UrgenceArrosage.pasNecessaire);
    expect(c.pluiePrevue, isTrue);
    expect(c.joursAvantArrosage, 1);
  });

  test('an oya in service lowers the need (equipment modifier applied)',
      () async {
    when(() => equipements.obtenirParParcelle('par1')).thenAnswer((_) async => [
          Equipement(
            id: 'eq1',
            nom: 'Oya',
            potagerId: 'pot1',
            type: TypeEquipement.oya,
            dateInstallation: DateTime.utc(2026, 4, 1),
          ),
        ]);
    when(() => meteo.obtenirPrevisions(loc, 3, joursPasses: 5))
        .thenAnswer((_) async => fenetre());

    final c = await useCase.executer(plantation: plantation, localisation: loc);
    // eleve 1.0 * oya 0.4 = 0.4 -> "bientot", and retention flagged.
    expect(c!.retentionRenforcee, isTrue);
    expect(c.urgence, UrgenceArrosage.bientot);
  });

  test('returns null when the plant is absent from the catalogue', () async {
    when(() => fiches.obtenirParId('inconnu')).thenAnswer((_) async => null);
    final p = Plantation(
      id: 'pl2',
      planteId: 'inconnu',
      parcelleId: 'par1',
      dateMiseEnPlace: DateTime.utc(2026, 5, 1),
      methode: MethodeMiseEnPlace.repiquage,
      surfaceOccupee: Surface.enMetresCarres(1),
      nombrePieds: 1,
    );
    expect(await useCase.executer(plantation: p, localisation: loc), isNull);
  });

  test('still advises (demand-only) when the weather is offline', () async {
    when(() => meteo.obtenirPrevisions(loc, 3, joursPasses: 5))
        .thenThrow(MeteoIndisponibleException('offline'));

    final c = await useCase.executer(plantation: plantation, localisation: loc);
    expect(c, isNotNull);
    expect(c!.urgence, UrgenceArrosage.arroserMaintenant); // high need, no rain data
  });

  test('skips weather entirely when the location is undefined', () async {
    final c = await useCase.executer(
      plantation: plantation,
      localisation: const Localisation.nonDefinie(),
    );
    expect(c!.urgence, UrgenceArrosage.arroserMaintenant);
    verifyNever(() => meteo.obtenirPrevisions(
        const Localisation.nonDefinie(), any(),
        joursPasses: any(named: 'joursPasses')));
  });
}
