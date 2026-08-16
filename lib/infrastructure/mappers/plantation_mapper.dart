import 'package:drift/drift.dart';

import '../../core/utils/date_iso.dart';
import '../../domain/entities/plantation.dart';
import '../../domain/enums/methode_mise_en_place.dart';
import '../../domain/enums/statut_plantation.dart';
import '../../domain/value_objects/surface.dart';
import '../database/app_database.dart';

/// Maps a [Plantation] between the domain entity and its drift row. Hydration is
/// shallow (harvests are loaded by `RecolteRepository`).
class PlantationMapper {
  const PlantationMapper();

  Plantation versEntite(PlantationRow r) => Plantation(
        id: r.id,
        planteId: r.planteId,
        parcelleId: r.parcelleId,
        dateMiseEnPlace: DateIso.depuisStockage(r.dateMiseEnPlace),
        methode: MethodeMiseEnPlace.values.byName(r.methode),
        surfaceOccupee: r.surfaceOccupeeUnite == 'cm2'
            ? Surface.enCentimetresCarres(r.surfaceOccupeeValeur)
            : Surface.enMetresCarres(r.surfaceOccupeeValeur),
        nombrePieds: r.nombrePieds,
        statut: StatutPlantation.values.byName(r.statut),
        dateFinReelle: DateIso.depuisStockageNullable(r.dateFinReelle),
        raisonFin: r.raisonFin,
      );

  PlantationsCompanion versCompanion(Plantation p) {
    final maintenant = DateIso.maintenant();
    return PlantationsCompanion(
      id: Value(p.id),
      parcelleId: Value(p.parcelleId),
      planteId: Value(p.planteId),
      dateMiseEnPlace: Value(DateIso.versStockage(p.dateMiseEnPlace)),
      methode: Value(p.methode.name),
      surfaceOccupeeValeur: Value(p.surfaceOccupee.enMetresCarres),
      surfaceOccupeeUnite: const Value('m2'),
      nombrePieds: Value(p.nombrePieds),
      statut: Value(p.statut.name),
      dateFinReelle: Value(DateIso.versStockageNullable(p.dateFinReelle)),
      raisonFin: Value(p.raisonFin),
      createdAt: Value(maintenant),
      updatedAt: Value(maintenant),
    );
  }
}
