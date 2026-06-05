import 'package:flutter_test/flutter_test.dart';
import 'package:pot_a_gerer/application/engine/calculateur_dates_culture.dart';
import 'package:pot_a_gerer/application/use_cases/estimer_recolte.dart';
import 'package:pot_a_gerer/domain/entities/fiche_plante.dart';
import 'package:pot_a_gerer/domain/entities/plantation.dart';
import 'package:pot_a_gerer/domain/enums/besoin_eau.dart';
import 'package:pot_a_gerer/domain/enums/categorie_plante.dart';
import 'package:pot_a_gerer/domain/enums/methode_mise_en_place.dart';
import 'package:pot_a_gerer/domain/enums/niveau_soleil.dart';
import 'package:pot_a_gerer/domain/enums/usage_plante.dart';
import 'package:pot_a_gerer/domain/value_objects/besoins_culture.dart';
import 'package:pot_a_gerer/domain/value_objects/surface.dart';
import 'package:pot_a_gerer/infrastructure/catalogue/fiche_plante_cache.dart';
import 'package:pot_a_gerer/infrastructure/repositories/fiche_plante_repository_impl.dart';

void main() {
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

  Plantation plantation(String planteId) => Plantation(
        id: 'pl1',
        planteId: planteId,
        parcelleId: 'par1',
        dateMiseEnPlace: DateTime.utc(2026, 5, 10),
        methode: MethodeMiseEnPlace.repiquage,
        surfaceOccupee: Surface.enMetresCarres(1),
        nombrePieds: 2,
      );

  final useCase = EstimerRecolte(
    FichePlanteRepositoryImpl(FichePlanteCache([tomate])),
    const CalculateurDatesCulture(),
  );

  test('estimates the harvest window from the matching plant sheet', () async {
    final est = await useCase.executer(plantation('tomate'));
    expect(est, isNotNull);
    expect(est!.dateMin, DateTime.utc(2026, 7, 19));
    expect(est.dateMax, DateTime.utc(2026, 8, 8));
  });

  test('returns null when the plant is absent from the catalogue', () async {
    expect(await useCase.executer(plantation('inconnu')), isNull);
  });
}
