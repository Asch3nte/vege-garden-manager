import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pot_a_gerer/application/engine/evaluateur_recommandations.dart';
import 'package:pot_a_gerer/application/use_cases/recommander_plantes.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/parcelle.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/hemisphere.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/famille_effet_association.dart';
import 'package:pot_a_gerer/domain/enums/niveau_besoin.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/poids_association.dart';
import 'package:pot_a_gerer/domain/enums/raison_reco.dart';
import 'package:pot_a_gerer/domain/enums/statut_plantation.dart';
import 'package:pot_a_gerer/domain/enums/type_climat.dart';
import 'package:pot_a_gerer/domain/enums/type_parcelle.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/enums/zone_rusticite.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_fiche_plante_repository.dart';
import 'package:pot_a_gerer/domain/repositories/abstract_plantation_repository.dart';
import 'package:pot_a_gerer/domain/value_objects/association_conflit.dart';
import 'package:pot_a_gerer/domain/value_objects/profil_ponderation_associations.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/localisation.dart';
import 'package:pot_a_gerer/domain/value_objects/periode.dart';
import 'package:pot_a_gerer/domain/value_objects/periodes_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/domain/value_objects/zone_climatique.dart';

class MockFiches extends Mock implements AbstractFichePlanteRepository {}

class MockPlantations extends Mock implements AbstractPlantationRepository {}

void main() {
  final juin = DateTime.utc(2026, 6, 15);
  const zone = ZoneClimatique(TypeClimat.oceanique, ZoneRusticite.zone8);
  final lyon =
      Localisation.manuelle(ville: 'Lyon', latitude: 45.75, longitude: 4.85);

  FichePlante fiche(
    String id,
    String famille,
    Periode plantation, {
    String? parentId,
    Set<String> conflits = const {},
    bool fixeAzote = false,
    NiveauBesoin? besoinAzote,
  }) =>
      FichePlante(
        id: id,
        parentId: parentId,
        nomScientifique: '$id sp',
        familleBotanique: famille,
        categorie: CategoriePlante.legume,
        usages: const {UsagePlante.alimentaire},
        nomsLocalises: {'fr': id},
        besoins: BesoinsCulture(
          eau: BesoinEau.modere,
          soleil: NiveauSoleil.pleinSoleil,
          phMin: 6,
          phMax: 7,
        ),
        espacementCm: 40,
        dureeAvantRecolteJoursMin: 60,
        dureeAvantRecolteJoursMax: 80,
        fixeAzote: fixeAzote,
        besoinAzote: besoinAzote,
        associationsNegatives: [
          for (final id in conflits) AssociationConflit(cibleId: id),
        ],
        periodes: {
          Hemisphere.nord: {
            TypeClimat.oceanique: PeriodesCulture(plantation: plantation),
          },
        },
      );

  // Plantable in June (5-6), and one that is not (Jan-Feb).
  final tomate = fiche('tomate', 'Solanaceae', const Periode(5, 6));
  final salade = fiche('salade', 'Asteraceae', const Periode(3, 9));
  final chou = fiche('chou', 'Brassicaceae', const Periode(1, 2));
  final catalogue = [tomate, salade, chou];

  Parcelle parcelle({TypeParcelle type = TypeParcelle.pleineTerre}) => Parcelle(
        id: 'par1',
        nom: 'Bac',
        potagerId: 'pot1',
        type: type,
        surface: Surface.enMetresCarres(4),
        exposition: NiveauSoleil.pleinSoleil,
      );

  Plantation plantation(
    String id,
    String planteId, {
    StatutPlantation statut = StatutPlantation.enCours,
    DateTime? dateMiseEnPlace,
    DateTime? dateFinReelle,
  }) =>
      Plantation(
        id: id,
        planteId: planteId,
        parcelleId: 'par1',
        dateMiseEnPlace: dateMiseEnPlace ?? DateTime.utc(2026, 5, 1),
        methode: MethodeMiseEnPlace.repiquage,
        surfaceOccupee: Surface.enMetresCarres(0.5),
        nombrePieds: 1,
        statut: statut,
        dateFinReelle: dateFinReelle,
        raisonFin: dateFinReelle == null ? null : 'fin',
      );

  late MockFiches fiches;
  late MockPlantations plantations;
  late RecommanderPlantes useCase;

  setUp(() {
    fiches = MockFiches();
    plantations = MockPlantations();
    useCase = RecommanderPlantes(
        fiches, plantations, const EvaluateurRecommandations());
    when(() => fiches.obtenirToutes()).thenAnswer((_) async => catalogue);
    when(() => plantations.obtenirParParcelle('par1'))
        .thenAnswer((_) async => const []);
  });

  Future<List<String>> recommander({
    TypeParcelle type = TypeParcelle.pleineTerre,
    Localisation? loc,
  }) async {
    final r = await useCase.executer(
      parcelle: parcelle(type: type),
      zoneClimatique: zone,
      localisation: loc ?? lyon,
      date: juin,
    );
    return r.recommandations.map((e) => e.planteId).toList();
  }

  test('recommends the in-season plants, excludes the out-of-season one',
      () async {
    final ids = await recommander();
    expect(ids, containsAll(['tomate', 'salade']));
    expect(ids, isNot(contains('chou'))); // plantable Jan-Feb only
  });

  test('derives a beneficial association reason from active plants (ADR-0010)',
      () async {
    // An active nitrogen-fixer (haricot) in the parcelle; the greedy candidate
    // (mais, besoin_azote eleve) should be flagged with a derived association.
    final haricot = fiche('haricot', 'Fabaceae', const Periode(5, 6),
        fixeAzote: true);
    final mais = fiche('mais', 'Poaceae', const Periode(5, 6),
        besoinAzote: NiveauBesoin.eleve);
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [haricot, mais]);
    when(() => plantations.obtenirParParcelle('par1'))
        .thenAnswer((_) async => [plantation('pl1', 'haricot')]);

    final r = await useCase.executer(
      parcelle: parcelle(),
      zoneClimatique: zone,
      localisation: lyon,
      date: juin,
    );
    final reco = r.recommandations.firstWhere((e) => e.planteId == 'mais');
    expect(reco.raisons, contains(RaisonReco.associationDeriveeFavorable));
  });

  test('ignoring an effect family drops its derived reco bonus (ADR-0011)',
      () async {
    final haricot = fiche('haricot', 'Fabaceae', const Periode(5, 6),
        fixeAzote: true);
    final mais = fiche('mais', 'Poaceae', const Periode(5, 6),
        besoinAzote: NiveauBesoin.eleve);
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [haricot, mais]);
    when(() => plantations.obtenirParParcelle('par1'))
        .thenAnswer((_) async => [plantation('pl1', 'haricot')]);

    // fixationAzote is in the "fertilité" family → ignore it.
    final r = await useCase.executer(
      parcelle: parcelle(),
      zoneClimatique: zone,
      localisation: lyon,
      date: juin,
      profil: ProfilPonderationAssociations.defaut()
          .avec(FamilleEffetAssociation.fertilite, PoidsAssociation.ignore),
    );
    final reco = r.recommandations.firstWhere((e) => e.planteId == 'mais');
    expect(reco.raisons, isNot(contains(RaisonReco.associationDeriveeFavorable)));
  });

  test('does not recommend a plant already growing in the parcelle', () async {
    when(() => plantations.obtenirParParcelle('par1'))
        .thenAnswer((_) async => [plantation('pl1', 'tomate')]);
    final ids = await recommander();
    expect(ids, isNot(contains('tomate')));
    expect(ids, contains('salade'));
  });

  test('rotation excludes the same family grown recently (soil-persistent)',
      () async {
    when(() => plantations.obtenirParParcelle('par1')).thenAnswer((_) async => [
          plantation('old', 'tomate',
              statut: StatutPlantation.recoltee,
              dateMiseEnPlace: DateTime.utc(2025, 5, 1),
              dateFinReelle: DateTime.utc(2025, 9, 1)),
        ]);
    final ids = await recommander(); // pleineTerre
    expect(ids, isNot(contains('tomate'))); // Solanaceae grown last year
    expect(ids, contains('salade'));
  });

  test('rotation is relaxed on a renewable container (pot)', () async {
    when(() => plantations.obtenirParParcelle('par1')).thenAnswer((_) async => [
          plantation('old', 'tomate',
              statut: StatutPlantation.recoltee,
              dateMiseEnPlace: DateTime.utc(2025, 5, 1),
              dateFinReelle: DateTime.utc(2025, 9, 1)),
        ]);
    final ids = await recommander(type: TypeParcelle.pot);
    expect(ids, contains('tomate')); // fresh potting soil resets rotation
  });

  test('flags saisonNonVerifiee and skips the season filter without location',
      () async {
    final r = await useCase.executer(
      parcelle: parcelle(),
      zoneClimatique: zone,
      localisation: const Localisation.nonDefinie(),
      date: juin,
    );
    expect(r.saisonNonVerifiee, isTrue);
    // chou (Jan-Feb) is no longer filtered out by season.
    expect(r.recommandations.map((e) => e.planteId), contains('chou'));
  });

  test('evaluates species only — varieties are never candidates (ADR-0005)',
      () async {
    final tomateCerise =
        fiche('tomate-v1', 'Solanaceae', const Periode(5, 6), parentId: 'tomate');
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [...catalogue, tomateCerise]);

    final ids = await recommander();
    expect(ids, isNot(contains('tomate-v1')));
    expect(ids, contains('tomate')); // its species is recommended instead
  });

  test('a planted variety blocks recommending its species (resolved to mother)',
      () async {
    final tomateCerise =
        fiche('tomate-v1', 'Solanaceae', const Periode(5, 6), parentId: 'tomate');
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [...catalogue, tomateCerise]);
    when(() => plantations.obtenirParParcelle('par1'))
        .thenAnswer((_) async => [plantation('pl1', 'tomate-v1')]);

    final ids = await recommander();
    expect(ids, isNot(contains('tomate'))); // species already present as a variety
    expect(ids, contains('salade'));
  });

  test('a companion conflict against a planted variety resolves to its species',
      () async {
    // 'ail' conflicts with the tomato species; a tomato *variety* is growing.
    final ail = fiche('ail', 'Amaryllidaceae', const Periode(3, 9),
        conflits: {'tomate'});
    final tomateCerise =
        fiche('tomate-v1', 'Solanaceae', const Periode(5, 6), parentId: 'tomate');
    when(() => fiches.obtenirToutes())
        .thenAnswer((_) async => [...catalogue, ail, tomateCerise]);
    when(() => plantations.obtenirParParcelle('par1'))
        .thenAnswer((_) async => [plantation('pl1', 'tomate-v1')]);

    final ids = await recommander();
    expect(ids, isNot(contains('ail'))); // conflict detected via parent resolution
  });

  test('results are ranked by descending score', () async {
    final r = await useCase.executer(
      parcelle: parcelle(),
      zoneClimatique: zone,
      localisation: lyon,
      date: juin,
    );
    final scores = r.recommandations.map((e) => e.score).toList();
    for (var i = 1; i < scores.length; i++) {
      expect(scores[i - 1], greaterThanOrEqualTo(scores[i]));
    }
  });
}
